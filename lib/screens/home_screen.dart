import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'results_screen.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? selectedOrigin;
  String? selectedDestination;
  DateTime? departureDate;
  DateTime? returnDate;
  int adults = 1;
  int children = 0;
  int infants = 0;
  List<Map<String, String>> airports =[ ];
  String? selectedTripType = 'IdaVolta';

  final TextEditingController _adultsController = TextEditingController();
  final TextEditingController _childrenController = TextEditingController();
  final TextEditingController _infantsController = TextEditingController();

  List<String> selectedAirlines = [];

  @override
 void initState() {
  super.initState();
  loadAirports();
  _adultsController.text = adults.toString();
  _childrenController.text = children.toString();
  _infantsController.text = infants.toString();
  
  if (airports.isNotEmpty) {
    selectedOrigin = airports[0]['Iata'];
    selectedDestination = airports[0]['Iata'];
  }
}

  @override
  void dispose() {
    _adultsController.dispose();
    _childrenController.dispose();
    _infantsController.dispose();
    super.dispose();
  }

  int getTotalPassengers() {
    return adults + children + infants;
  }

Future<void> loadAirports() async {
  try {
    airports = await APIService().getAirports();
    setState(() {});
  
  } catch (e) {
    print('Error: $e');
  }
}

  final List<String> airlineCompanies = [
    'AMERICAN AIRLINES',
    'GOL',
    'IBERIA',
    'INTERLINE',
    'LATAM',
    'AZUL',
    'TAP',
  ];

  void submitSearch() async {

    if (getTotalPassengers() > 9) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: const Text('O número total de passageiros excede 9.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return; 
    }

    if (_formKey.currentState!.validate()) {
      
      final params = {
        'Companhias': selectedAirlines.isNotEmpty ? selectedAirlines : ['AZUL'],
        'DataIda': DateFormat('dd/MM/yyyy').format(departureDate!),
        'DataVolta': returnDate != null
            ? DateFormat('dd/MM/yyyy').format(returnDate!)
            : null,
        'Origem': selectedOrigin,
        'Destino': selectedDestination,
        'Tipo': selectedTripType
      };

      try {
        String searchId = await APIService().createSearch(params);

        Map<String, dynamic> results = await APIService().getSearchResults(searchId);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              results: results,
              adults: adults,
              children: children,
            ),
          ),
        );
      } catch (e) {

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: const Text('Algo deu errado. Por favor tente novamente mais tarde.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar voos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
               airports.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                  //DropdownButtonFormField para o aeroporto de origem
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Aeropórto de origem',
                      prefixIcon: const Icon(Icons.airplane_ticket),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    value: selectedOrigin,
                    items: airports.map((airport) {
                      return DropdownMenuItem<String>(
                        value: airport['Iata'],
                        child: Text(
                          '${airport['Nome']} (${airport['Iata']})',
                          style: const TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedOrigin = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select an origin airport';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 12),
                airports.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        //DropdownButtonFormField para o aeroporto de destino
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Aeropórto de destino',
                          prefixIcon: const Icon(Icons.airplane_ticket_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        value: selectedDestination,
                        items: airports.map((airport) {
                        return DropdownMenuItem<String>(
                          value: airport['Iata'], 
                          child: Text(
                            '${airport['Nome']} (${airport['Iata']})', 
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDestination = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a destination airport';
                          }
                          return null;
                        },
                      ),
                const SizedBox(height: 12),
                //TextFormField para o Data de ida 
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Data de ida',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: departureDate ?? DateTime.now().add(const Duration(days: 1)), 
                      firstDate: DateTime.now().add(const Duration(days: 1)), 
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != departureDate) {
                      setState(() {
                        departureDate = pickedDate;
                      });
                    }
                  },
                  readOnly: true,
                  controller: TextEditingController(
                    text: departureDate != null
                        ? '${departureDate!.toLocal()}'.split(' ')[0]
                        : '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a departure date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (selectedTripType == 'IdaVolta')
                  //TextFormField para o Data de volta 
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Data de volta',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onTap: () async {
                      if (departureDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a Departure Date first')),
                        );
                        return;
                      }

                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: returnDate ?? departureDate!.add(const Duration(days: 1)), 
                        firstDate: departureDate!.add(const Duration(days: 1)), 
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null && pickedDate != returnDate) {
                        setState(() {
                          returnDate = pickedDate;
                        });
                      }
                    },
                    readOnly: true,
                    controller: TextEditingController(
                      text: returnDate != null
                          ? '${returnDate!.toLocal()}'.split(' ')[0]
                          : '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor escolha uma data de retorno';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 12),
                //TextFormField para o Número de passageiros adultos
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Adultos (≥1)',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  controller: _adultsController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    int newAdults = int.tryParse(value) ?? 1;
                    if (newAdults < 1) {
                      newAdults = 1;
                      _adultsController.text = newAdults.toString();
                    }
                    setState(() {
                      adults = newAdults;
                      // Automatically adjust infants if needed
                      if (infants > newAdults) {
                        infants = newAdults;
                        _infantsController.text = infants.toString();
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Por favor escreva a quantidade de adultos';
                    int? parsedValue = int.tryParse(value);
                    if (parsedValue == null || parsedValue < 1) return 'Número de adultos deve ser ≥1';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                //TextFormField para o Número de passageiros crianças
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Crianças (≥0)',
                    prefixIcon: const Icon(Icons.child_care),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  controller: _childrenController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      children = int.tryParse(value) ?? 0;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Por favor escreva a quantidade de crianças';
                    int? parsedValue = int.tryParse(value);
                    if (parsedValue == null || parsedValue < 0) return 'Número de crianças deve ser ≥0';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                //TextFormField para o Número de passageiros bebês
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Bebês  (≤ Adultos)',
                    prefixIcon: const Icon(Icons.baby_changing_station),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  controller: _infantsController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    int newInfants = int.tryParse(value) ?? 0;
                    if (newInfants > adults) {
                      newInfants = adults;
                      _infantsController.text = newInfants.toString();
                    }
                    setState(() {
                      infants = newInfants;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Por favor escreva a quantidade de bebês';
                    int? parsedValue = int.tryParse(value);
                    if (parsedValue == null || parsedValue < 0) return 'Número de crianças deve ser ≥0';
                    if (parsedValue > adults) return 'Número de bebês não pode exceder o número de adlutos';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                //MultiSelectDialogField para as companias aereas
                MultiSelectDialogField<String>(
                  
                  items: airlineCompanies
                      .map((airline) => MultiSelectItem<String>(airline, airline))
                      .toList(),
                  title: const Text('Selecione companhias Aéreas'),
                  selectedColor: Colors.deepPurple,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurple),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  buttonText: const Text('Selecione companias', style: TextStyle(color: Colors.deepPurple)),
                  onConfirm: (values) {
                    setState(() {
                      selectedAirlines = values;
                    });
                  },
                  validator: (values) {
                    if (values == null || values.isEmpty) {
                      return 'Por favor selecione pleno menos uma companhia Aérea';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                //Radiobox selecionar tipo de viajem
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ListTile(
                        title: const Text('Somente ida'),
                        leading: Radio<String>(
                          value: 'Ida',
                          groupValue: selectedTripType,
                          onChanged: (String? value) {
                            setState(() {
                              selectedTripType = value;
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('Ida e volta'),
                        leading: Radio<String>(
                          value: 'IdaVolta',
                          groupValue: selectedTripType,
                          onChanged: (String? value) {
                            setState(() {
                              selectedTripType = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                //Botão de envio de requisições
                Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: submitSearch,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.deepPurple),
                      ),
                      child: Text(
                        'Buscar voos',
                        style: TextStyle(color: Colors.white), 
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
