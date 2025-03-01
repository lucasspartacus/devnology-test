import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> results;
  final int adults;
  final int children;

  const ResultsScreen({super.key, 
    required this.results,
    required this.adults,
    required this.children,
  });

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool isBRLSelected = true;
  final Set<int> _expandedIndices = {}; 
  late DateTime _dataCreatedTime;
  late Timer _timer;
  late int _remainingTimeInSeconds;

  @override
  void initState() {
    super.initState();
    _dataCreatedTime = DateTime.now(); 
    _remainingTimeInSeconds = 30 * 60; 
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel(); 
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTimeInSeconds > 0) {
          _remainingTimeInSeconds--;
        } else {
          _timer.cancel(); 
          _clearData(); 
        }
      });
    });
  }

  void _clearData() {
    setState(() {
      widget.results.clear(); 
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  double calculateTotalPrice(Map<String, dynamic> voo) {
    final prices = isBRLSelected ? voo['Valor'][0] : voo['Milhas'][0];
    final adultPrice = prices['Adulto'] ?? 0.0;
    final childPrice = prices['Crianca'] ?? 0.0;
    final boardingFee = prices['TaxaEmbarque'] ?? 0.0;

    return (adultPrice * widget.adults) +
        (childPrice * widget.children) +
        (boardingFee * (widget.adults + widget.children));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Buscar voos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Dados expiraram, realize outra busca.'),
            const SizedBox(height: 20), 
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()), 
                );
              },
              style:ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.deepPurple),
              ),
              child: Text('Voltar para busca', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      );
    }

    List<dynamic> voos = widget.results['Voos'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar voos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ToggleButtons(
              isSelected: [isBRLSelected, !isBRLSelected],
              onPressed: (index) {
                setState(() {
                  isBRLSelected = index == 0;
                });
              },
              children: [Text('BRL'), Text('Milhas')],
            ),
            const SizedBox(height: 16),
            Text(
              'Dados expiram em: ${_formatTime(_remainingTimeInSeconds)}',
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: voos.length,
                itemBuilder: (context, index) {
                  final voo = voos[index];
                  final totalPrice = calculateTotalPrice(voo);
                  final isExpanded = _expandedIndices.contains(index);

                  return Card(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedIndices.remove(index);
                          } else {
                            _expandedIndices.add(index);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  voo['Companhia'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('${voo['Origem']} → ${voo['Destino']}'),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Embarque : ${voo['Embarque']}'),
                                    Text('Desembarque : ${voo['Desembarque']}'),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Conexões: ${voo['NumeroConexoes']}'),
                                    Text('Duração: ${voo['Duracao']}'),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Preço total: ${isBRLSelected ? 'BRL' : 'Milhas'} '
                              '${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                            if (isExpanded) ...[const SizedBox(height: 12), _buildPriceBreakdown(voo)],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown(Map<String, dynamic> voo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'Detalhamento do preço:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildBreakdownRow(
          'Adultos(${widget.adults})',
          voo[isBRLSelected ? 'Valor' : 'Milhas'][0]['Adulto'],
        ),
        _buildBreakdownRow(
          'Crianças(${widget.children})',
          voo[isBRLSelected ? 'Valor' : 'Milhas'][0]['Crianca'],
        ),
        _buildBreakdownRow(
          'Taxa de embarque(${widget.adults + widget.children}x)',
          voo[isBRLSelected ? 'Valor' : 'Milhas'][0]['TaxaEmbarque'],
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${isBRLSelected ? 'BRL' : 'Milhas'} ${(value is num ? value : 0.0).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
