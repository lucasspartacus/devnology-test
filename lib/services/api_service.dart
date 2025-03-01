import 'dart:convert';
import 'package:http/http.dart' as http;

class APIService {
  static const String _baseUrl = 'https://buscamilhas.mock.gralmeidan.dev';

  List<String> allowedAirports = ['GRU', 'CGH', 'VCP', 'GIG', 'SDU', 'CNF', 'PLU' ];

  Future<List<Map<String, String>>> getAirports() async {


    List<Map<String, String>> airports = [];

    for (String query in allowedAirports) {

      final response = await http.get(Uri.parse('$_baseUrl/aeroportos?q=$query'));

      if (response.statusCode == 200) {

        List<dynamic> data = jsonDecode(response.body);
  
        for (var airportData in data) {
          airports.add({
            'Nome': airportData['Nome'],
            'Iata': airportData['Iata'],
          });
        }
      } else {

        throw Exception('Failed to load airport data');
      }
    }

    return airports;
  }

  Future<String> createSearch(Map<String, dynamic> params) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/busca/criar'),
    headers: {
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    },
    body: json.encode(params),
  );

  if (response.statusCode == 201) {

    final Map<String, dynamic> responseBody = json.decode(response.body);
    
    return responseBody['Busca'] as String;
  } else {
    throw Exception('Failed to create search: ${response.statusCode}');
  }
}

  Future<Map<String, dynamic>> getSearchResults(String searchId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/busca/$searchId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load results: ${response.statusCode}');
    }
  }
}