import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:device_apps/device_apps.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? storedCedula = prefs.getString('cedula');
  bool? hasCompletedPreferences = prefs.getBool('hasCompletedPreferences');

  runApp(MaterialApp(
    // home: storedCedula == null ? WelcomeScreen() : MyApp(cedula: storedCedula),
    home: storedCedula == null
        ? WelcomeScreen()
        : (hasCompletedPreferences == true
            ? MyApp(cedula: storedCedula)
            : UserPreferencesScreen()),
    // theme: ThemeData(primarySwatch: Colors.blue),
    theme: ThemeData(
      primarySwatch: Colors.blue,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF002856),
        selectionColor: Color(0xFF002856),
        selectionHandleColor: Color(0xFF002856),
      ),
    ),
  ));
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

// Widget Terminos y condiciones
class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _cedulaController = TextEditingController();
  bool _isAccepted = false;
  bool _isModalShown = false;

  @override
  Widget build(BuildContext context) {
    if (!_isModalShown) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        _showWelcomeModal(context);
      });
      _isModalShown = true;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Términos y Condiciones',
          style: TextStyle(
            fontFamily: 'FFMetaProText2',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF002856),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text(
                      'Estos términos y condiciones describen las reglas y regulaciones para el uso de nuestra aplicación. '
                      'Al acceder a esta aplicación, asumimos que acepta estos términos y condiciones en su totalidad. '
                      'No continúe utilizando la aplicación si no acepta todos los términos y condiciones establecidos en esta página. '
                      'El siguiente lenguaje se aplica a estos términos y condiciones, política de privacidad y aviso de responsabilidad: '
                      'Cliente, usted y su se refiere a usted, la persona que accede a esta aplicación y acepta los términos y condiciones de la Compañía.',
                      style: TextStyle(
                        fontFamily: 'FFMetaProText3',
                        color: Color(0xFF002856),
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: _isAccepted,
                          onChanged: (bool? value) {
                            setState(() {
                              _isAccepted = value ?? false;
                            });
                          },
                        ),
                        const Text('Aceptar términos y condiciones'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isAccepted
                  ? () {
                      _showCedulaDialog(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF002856), // Color de fondo
                onPrimary: Colors.white, // Color del texto
              ),
              child: const Text(
                'Ingresar',
                style: TextStyle(
                  fontFamily: 'FFMetaProText2',
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Muestra el panel inicial
  void _showWelcomeModal(BuildContext context) {
    Future.delayed(Duration(milliseconds: 600), () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF002856),
        builder: (BuildContext context) {
          return FractionallySizedBox(
            heightFactor: 0.80,
            child: Container(
              padding: EdgeInsets.all(50.0),
              // color: Color(0xFF002856),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/icono.png',
                    height: 200,
                  ),
                  // const SizedBox(height: 25.0),
                  const Text(
                    'Bienvenid@ a CIARA',
                    style: TextStyle(
                      fontSize: 26.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'FFMetaProText2',
                    ),
                  ),
                  const SizedBox(height: 25.0),
                  const Text(
                    'Esta aplicación reúne tu información del uso diario de tu teléfono celular.\n \nPuedes revisar parámetros de uso, alertas y sugerencias',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'FFMetaProText3',
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        fontFamily: 'FFMetaProText2',
                        fontSize: 20,
                        color: Color(0xFF002856),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  bool validarCedulaEcuatoriana(String cedula) {
    if (cedula.length != 10) return false;

    final List<int> coefficients = [2, 1, 2, 1, 2, 1, 2, 1, 2];
    final int provinceCode = int.parse(cedula.substring(0, 2));

    // Validar el código de provincia
    if (provinceCode < 1 || provinceCode > 24) return false;

    int total = 0;

    for (int i = 0; i < coefficients.length; i++) {
      int value = int.parse(cedula[i]) * coefficients[i];
      total += value > 9 ? value - 9 : value;
    }

    final int verificationDigit = int.parse(cedula[9]);
    final int calculatedVerificationDigit =
        total % 10 == 0 ? 0 : 10 - (total % 10);

    return verificationDigit == calculatedVerificationDigit;
  }

  void _showCedulaDialog(BuildContext context) {
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Ingresar cédula',
                style: TextStyle(
                  fontFamily: 'FFMetaProText2',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002856),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _cedulaController,
                    style: const TextStyle(
                      color: Color(0xFF002856), // Color del texto del input
                      fontFamily: 'FFMetaProText3',
                      fontSize: 16,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    cursorColor: Color(0xFF002856),
                    decoration: InputDecoration(
                      labelText: 'Número de cédula*',
                      labelStyle: const TextStyle(
                        color: Color(0xFF002856),
                        fontFamily: 'FFMetaProText3',
                        fontSize: 16,
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(
                              0xFFA51008), // Color de la línea inferior cuando no está enfocado
                        ),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(
                              0xFFA51008), // Color de la línea inferior cuando está enfocado
                        ),
                      ),
                      errorText: errorMessage.isEmpty ? null : errorMessage,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white, // Color de fondo
                    onPrimary: Color(0xFF002856), // Color del texto
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontFamily: 'FFMetaProText2',
                      fontSize: 20,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String cedula = _cedulaController.text;
                    if (cedula.length != 10) {
                      setState(() {
                        errorMessage = 'La cédula debe tener 10 dígitos';
                      });
                      return;
                    }

                    // Guardar cédula y navegar a la siguiente pantalla
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.setString('cedula', cedula);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        // builder: (context) => MyApp(cedula: cedula),
                        builder: (context) => UserPreferencesScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF002856), // Color de fondo
                    onPrimary: Colors.white, // Color del texto
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(
                      fontFamily: 'FFMetaProText2',
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class UserPreferencesScreen extends StatefulWidget {
  const UserPreferencesScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UserPreferencesScreenState createState() => _UserPreferencesScreenState();
}

//formato  y envio de preferencias a server
class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  final Map<String, List<bool>> _selectedOptions = {
    'peliculas': List.generate(6, (_) => false),
    'musica': List.generate(7, (_) => false),
    'series': List.generate(6, (_) => false),
    'libros': List.generate(6, (index) => false),
    'formatoLectura': List.generate(3, (_) => false),
    'actividades': List.generate(6, (_) => false),
    'frecuenciaActividades': List.generate(6, (_) => false),
    'actividadesInteriores': List.generate(6, (_) => false),
    'tiempoInteriores': List.generate(4, (_) => false),
    'destinosViaje': List.generate(6, (_) => false),
    'actividadesViaje': List.generate(6, (_) => false),
    'gadgets': List.generate(6, (_) => false),
    'aplicaciones': List.generate(6, (_) => false),
    'comida': List.generate(6, (_) => false),
    'frecuenciaComida': List.generate(6, (_) => false),
    'deportes': List.generate(6, (_) => false),
    'frecuenciaDeportes': List.generate(6, (_) => false),
  };

  final Map<String, String> _preferences = {};

  bool get _isFormComplete {
    return _preferences.length ==
        _selectedOptions
            .length; // Cambia este valor según el número de preguntas
  }

  void _updatePreference(String question, int index, List<String> options) {
    setState(() {
      _selectedOptions[question] =
          List.generate(options.length, (i) => i == index);
      _preferences[question] = options[index];
    });
  }

  Future<void> _submitPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('hasCompletedPreferences', true);

    // Enviar las preferencias al servidor
    try {
      // var url =
      //     Uri.parse('https://ingsoftware.ucuenca.edu.ec/enviar-preferencias');
      var url = Uri.parse('http://10.24.160.140:8080/enviar-preferencias');
      var response = await http.post(
        url,
        body: {
          'cedula': prefs.getString('cedula'),
          'peliculas': _preferences['peliculas'],
          'musica': _preferences['musica'],
          'series': _preferences['series'],
          'libros': _preferences['libros'],
          'formatoLectura': _preferences['formatoLectura'],
          'actividadesAlAireLibre': _preferences['actividades'],
          'frecuenciaActividadesAlAireLibre':
              _preferences['frecuenciaActividades'],
          'actividadesEnInteriores': _preferences['actividadesInteriores'],
          'tiempoActividadesEnInteriores': _preferences['tiempoInteriores'],
          'destinosDeViaje': _preferences['destinosViaje'],
          'actividadesEnViaje': _preferences['actividadesViaje'],
          'gadgets': _preferences['gadgets'],
          'aplicaciones': _preferences['aplicaciones'],
          'tipoComida': _preferences['comida'],
          'frecuenciaComerFuera': _preferences['frecuenciaComida'],
          'deportes': _preferences['deportes'],
          'frecuenciaEjercicio': _preferences['frecuenciaDeportes'],
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    } catch (error) {
      print('Error al enviar las preferencias: $error');
    }

    // Navegar a la aplicación principal
    // ignore: use_build_context_synchronously
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => MyApp(cedula: prefs.getString('cedula')!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Se crea el contenido de la vista de preferencias
      appBar: AppBar(
        title: const Text('Gustos y Preferencias'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '1. Entretenimiento',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('1.1. ¿Qué tipo de películas prefieres?'),
              _buildToggleButtons('peliculas', [
                'Acción',
                'Comedia',
                'Drama',
                'Ciencia ficción',
                'Terror',
                'Documentales'
              ]),
              const SizedBox(height: 20),
              const Text('1.2. ¿Cuál es tu género musical favorito?'),
              _buildToggleButtons('musica', [
                'Pop',
                'Rock',
                'Reggaeton',
                'Clásica',
                'Electrónica',
                'Hip-hop/Rap',
                'Otro',
              ]),
              const SizedBox(height: 20),
              const Text('1.3. ¿Qué tipo de series te gustan más?'),
              _buildToggleButtons('series', [
                'Policíacas',
                'Comedias',
                'Drama',
                'Ciencia ficción',
                'Fantasía',
                'Documentales'
              ]),
              const SizedBox(height: 20),
              const Text(
                '2. Lectura',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('2.1. ¿Qué tipo de libros prefieres leer?'),
              _buildToggleButtons('libros', [
                'Novelas',
                'Biografías',
                'Ciencia ficción',
                'No ficción',
                'Autoayuda',
                'Fantasía'
              ]),
              const SizedBox(height: 20),
              const Text('2.2. ¿Qué formato de lectura prefieres?'),
              _buildToggleButtons('formatoLectura', [
                'Libros impresos',
                'Libros electrónicos (eBooks)',
                'Audiolibros'
              ]),
              const SizedBox(height: 20),
              const Text(
                '3. Actividades al aire libre',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('3.1. ¿Qué actividades al aire libre disfrutas más?'),
              _buildToggleButtons('actividades', [
                'Senderismo',
                'Ciclismo',
                'Camping',
                'Running',
                'Deportes acuáticos',
                'Pasear en la ciudad'
              ]),
              const SizedBox(height: 20),
              const Text(
                  '3.2. ¿Con qué frecuencia realizas actividades al aire libre?'),
              _buildToggleButtons('frecuenciaActividades', [
                'Diariamente',
                'Varias veces a la semana',
                'Una vez a la semana',
                'Un par de veces al mes',
                'Rara vez',
                'Nunca'
              ]),
              const SizedBox(height: 20),
              const Text(
                '4. Actividades en interiores',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                  '4.1. ¿Qué tipo de actividades en interiores prefieres?'),
              _buildToggleButtons('actividadesInteriores', [
                'Cocinar',
                'Manualidades/DIY',
                'Juegos de mesa',
                'Videojuegos',
                'Yoga/meditación',
                'Lectura'
              ]),
              const SizedBox(height: 20),
              const Text(
                  '4.2. ¿Cuánto tiempo dedicas a actividades en interiores en una semana?'),
              _buildToggleButtons('tiempoInteriores', [
                'Menos de 5 horas',
                'Entre 5 y 10 horas',
                'Entre 10 y 15 horas',
                'Más de 15 horas'
              ]),
              const SizedBox(height: 20),
              const Text(
                '5. Viajes y exploración',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('5.1. ¿Qué tipo de destinos prefieres para viajar?'),
              _buildToggleButtons('destinosViaje', [
                'Playas',
                'Montañas',
                'Ciudades históricas',
                'Parques naturales',
                'Ciudades modernas',
                'Destinos culturales'
              ]),
              const SizedBox(height: 20),
              const Text(
                  '5.2. ¿Qué tipo de actividades disfrutas más durante tus viajes?'),
              _buildToggleButtons('actividadesViaje', [
                'Turismo gastronómico',
                'Visitas culturales (museos, monumentos)',
                'Actividades deportivas',
                'Compras',
                'Relajación (spa, playa)',
                'Aventuras (excursiones, deportes extremos)'
              ]),
              const SizedBox(height: 20),
              const Text(
                '6. Tecnologías y gadgets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('6.1. ¿Qué tipo de gadgets usas con más frecuencia?'),
              _buildToggleButtons('gadgets', [
                'Teléfonos inteligentes',
                'Tablets',
                'Computadoras portátiles',
                'Consolas de videojuegos',
                'Relojes inteligentes',
                'Auriculares inalámbricos'
              ]),
              const SizedBox(height: 20),
              const Text('6.2. ¿Qué aplicaciones utilizas con más frecuencia?'),
              _buildToggleButtons('aplicaciones', [
                'Redes sociales',
                'Aplicaciones de mensajería',
                'Aplicaciones de streaming (música/películas)',
                'Aplicaciones de productividad (calendarios, notas)',
                'Aplicaciones de fitness y salud',
                'Aplicaciones de noticias'
              ]),
              const SizedBox(height: 20),
              const Text(
                '7. Gastronomía',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('7.1. ¿Cuál es tu tipo de comida favorita?'),
              _buildToggleButtons('comida', [
                'Italiana',
                'Mexicana',
                'Japonesa',
                'India',
                'Mediterránea',
                'Americana'
              ]),
              const SizedBox(height: 20),
              const Text('7.2. ¿Con qué frecuencia comes fuera de casa?'),
              _buildToggleButtons('frecuenciaComida', [
                'Diariamente',
                'Varias veces a la semana',
                'Una vez a la semana',
                'Varias veces al mes',
                'Rara vez',
                'Nunca'
              ]),
              const SizedBox(height: 20),
              const Text(
                '8. Deportes y fitness',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('8.1. ¿Qué deportes practicas regularmente?'),
              _buildToggleButtons('deportes', [
                'Fútbol',
                'Baloncesto',
                'Natación',
                'Ciclismo',
                'Running',
                'Ninguno'
              ]),
              const SizedBox(height: 20),
              const Text('8.2. ¿Con qué frecuencia haces ejercicio?'),
              _buildToggleButtons('frecuenciaDeportes', [
                'Diariamente',
                'Varias veces a la semana',
                'Una vez a la semana',
                'Varias veces al mes',
                'Rara vez',
                'Nunca'
              ]),
              //here
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isFormComplete ? _submitPreferences : null,
                child: const Text('Generar Perfil de Usuario'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButtons(String question, List<String> options) {
    return Wrap(
      spacing: 8.0,
      children: List.generate(options.length, (index) {
        return ChoiceChip(
          label: Text(options[index]),
          selected: _selectedOptions[question]![index],
          onSelected: (selected) {
            _updatePreference(question, index, options);
          },
        );
      }),
    );
  }
}

class MyApp extends StatefulWidget {
  final String cedula;
  MyApp({required this.cedula});
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String cedula = '';
  List<UsageInfo> usageInfoList = [];
  int _currentIndex = 0;
  bool notificationEnabled = false;
  bool alternativasEnabled = false;
  bool sugerenciasEnabled = false;
  DateTime currentDate = DateTime.now().toLocal();
  DateTime startDate = DateTime.now().toLocal();
  DateTime endDate = DateTime.now().toLocal();

  String _mostActiveHour = '';
  List<Map<String, dynamic>> _usageData = [];

  @override
  void initState() {
    super.initState();
    _getMostActiveHour(currentDate);
    //requestPermissions();
    initUsage();
    getCedula();

    Timer.periodic(Duration(minutes: 5), (Timer timer) {
      initUsage();
    });
  }

  Future<void> requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      print('Storage permission granted');
    } else {
      print('Storage permission denied');
    }
  }

  Future<void> initUsage() async {
    try {
      UsageStats.grantUsagePermission();
      startDate = DateTime(
          currentDate.year, currentDate.month, currentDate.day, 0, 0, 1);
      endDate = DateTime(
          currentDate.year, currentDate.month, currentDate.day, 23, 59, 59);

      List<UsageInfo> usageInfos =
          await UsageStats.queryUsageStats(startDate, endDate);

      List<UsageInfo> filteredUsageInfos = usageInfos
          .where((info) =>
              double.parse(info.totalTimeInForeground!) > 5 * 60 * 1000)
          .toList();
      setState(() {
        usageInfoList = filteredUsageInfos;
      });
    } catch (err) {
      print("Error: $err");
    }
  }

  Future<void> _refresh() async {
    await initUsage();
    // Obtiene la hora actual
    DateTime currentDate = DateTime.now().toLocal();

    // Verifica si es UTC y conviértelo a local si es necesario
    if (currentDate.isUtc) {
      currentDate = currentDate.toLocal();
    }

    // Formatea la fecha y hora
    String formattedDate = DateFormat('yyyy-MM-dd / HH:mm').format(currentDate);

    // String formattedDate = DateFormat('yyyy-MM-dd / HH:mm').format(currentDate);

    // String formattedDate = currentDate.toIso8601String();
    String mostHour = _mostActiveHour;

    // Ordena la lista por totalTimeInForeground de mayor a menor
    usageInfoList.sort((a, b) => int.parse(b.totalTimeInForeground!)
        .compareTo(int.parse(a.totalTimeInForeground!)));

    // Toma los primeros 5 elementos después de ordenar
    List<UsageInfo> firstFiveUsageInfo = usageInfoList.take(5).toList();

    List<Map<String, dynamic>> dataToSend =
        await Future.wait(firstFiveUsageInfo.map((info) async {
      return {
        'packageName': await getAppNameFromPackageName(info.packageName!),
        'totalTimeInForeground':
            int.parse(info.totalTimeInForeground!) ~/ 60000,
      };
    }));

    try {
      // var url = Uri.parse('https://ingsoftware.ucuenca.edu.ec/enviar-datos');
      var url = Uri.parse('http://10.24.160.140:8080/enviar-datos');
      var response = await http.post(
        url,
        body: {
          'cedula': widget.cedula,
          'fecha': formattedDate,
          'mayorConsumo': mostHour, // Obtener la mayor hora de consumo
          'usageData': jsonEncode(
              dataToSend), // Envía la lista de datos de uso al servidor
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    } catch (error) {
      print('Error al enviar los datos: $error');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context);
  }

  //actualiza el dia
  void _updateDate(int days) {
    setState(() {
      currentDate = currentDate.add(Duration(days: days));
      if (currentDate.isAfter(DateTime.now().toLocal())) {
        currentDate = DateTime.now().toLocal();
      } else if (currentDate
          .isBefore(DateTime.now().toLocal().subtract(Duration(days: 30)))) {
        currentDate = DateTime.now().toLocal().subtract(Duration(days: 30));
      }
      usageInfoList.clear();
    });
    initUsage();
    _getMostActiveHour(currentDate);
  }

  //Construye el widget inicial general, navbar, menu desplegable
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "CIARA",
          style: TextStyle(color: Colors.white, fontFamily: 'FFMetaProText2'),
        ),
        backgroundColor: Color(0xFF002856),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refresh();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF002856),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundImage: AssetImage('assets/images/icono.png'),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'CIARA',
                    style: TextStyle(
                      fontFamily: 'FFMetaProText1',
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bienvenid@ : ${cedula.length >= 10 ? '******${cedula.substring(6)}' : ''}',
                        style: const TextStyle(
                          fontFamily: 'FFMetaProText1',
                          color: Colors.white,
                          fontSize: 19,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 0.0)
                      .add(const EdgeInsets.only(left: 2.0, right: 80.0)),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFA51008),
                        width: 3.0,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Estadísticas de uso',
                    style: TextStyle(
                      fontFamily: 'FFMetaProText4',
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              onTap: () {
                _onTabTapped(0);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 0.0)
                      .add(const EdgeInsets.only(left: 2.0, right: 120.0)),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color.fromRGBO(165, 16, 8, 1.0),
                        width: 3.0,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Notificaciones',
                    style: TextStyle(
                      fontFamily: 'FFMetaProText4',
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              onTap: () {
                _onTabTapped(1);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 0.0)
                      .add(const EdgeInsets.only(left: 2.0, right: 180.0)),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFA51008),
                        width: 3.0,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Ajustes',
                    style: TextStyle(
                      fontFamily: 'FFMetaProText4',
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              onTap: () {
                _onTabTapped(2);
              },
            ),
            const SizedBox(height: 280),
            Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 8),
              child: const Text(
                'UCUENCA',
                style: TextStyle(
                  fontFamily: 'FFMetaProTitle',
                  color: Color(0xFF6F6F6F),
                  fontSize: 50,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHome();
      case 1:
        return _buildNotificaciones();
      case 2:
        return _buildAjustes();
      default:
        return _buildHome();
    }
  }

  //Construye la vista inicial o home
  Widget _buildHome() {
    usageInfoList.sort((a, b) =>
        int.parse(b.totalTimeInForeground!) -
        int.parse(a.totalTimeInForeground!));
    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text('Fecha reporte:',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'FFMetaProTitle')),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _updateDate(-1);
                  },
                ),
                Text(
                  '${currentDate.toLocal()}'.split(' ')[0],
                  style: const TextStyle(fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    _updateDate(1);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Text('Hora de mayor uso:',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'FFMetaProTitle')),
                    const SizedBox(width: 8),
                    Text(
                      _mostActiveHour,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal, // Sin negrita
                          fontFamily: 'FFMetaProText1'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Gráfica del tiempo de uso:',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'FFMetaProTitle')),
              ),
            ),
            SingleChildScrollView(
              child: _buildPieChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificaciones() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Configuración de notificaciones',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildNotificacionesList(),
        ],
      ),
    );
  }

  Widget _buildNotificacionesList() {
    return Expanded(
      child: ListView(
        children: [
          _buildNotificacionItem("Notificaciones", notificationEnabled),
          _buildNotificacionItem("Límites", sugerenciasEnabled),
          _buildNotificacionItem("Alertas", alternativasEnabled),
        ],
      ),
    );
  }

  Widget _buildNotificacionItem(String itemName, bool itemEnabled) {
    return Dismissible(
      key: Key(itemName),
      onDismissed: (direction) {
        print("$itemName deslizado en dirección $direction");
      },
      background: Container(
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        child: ListTile(
          title: Text(itemName),
          trailing: Switch(
            value: itemEnabled,
            onChanged: (value) {
              setState(() {
                if (itemName == "Notificaciones") {
                  notificationEnabled = value;
                } else if (itemName == "Sugerencias") {
                  sugerenciasEnabled = value;
                } else if (itemName == "Alternativas") {
                  alternativasEnabled = value;
                }
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAjustes() {
    return const Center(
      child: Text('Página de Ajustes'),
    );
  }

  Widget _buildPieChart() {
    int totalTime = 0;
    usageInfoList.forEach((info) {
      totalTime += int.parse(info.totalTimeInForeground!);
    });

    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.grey,
    ];

    return FutureBuilder<List<String>>(
      future: getAppNames(usageInfoList),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          List<String> appNames = snapshot.data!;
          List<String> displayAppNames = [];
          List<int> appTimes = [];
          for (int i = 0; i < usageInfoList.length && i < 6; i++) {
            UsageInfo appInfo = usageInfoList[i];
            displayAppNames.add(appNames[i]);
            appTimes.add(int.parse(appInfo.totalTimeInForeground!) ~/ 60000);
          }

          if (usageInfoList.length > 6) {
            int otrosTime = 0;
            for (int i = 6; i < usageInfoList.length; i++) {
              otrosTime += int.parse(usageInfoList[i].totalTimeInForeground!);
            }
            // appNames.add("Otros");
            displayAppNames.add("Otros");
            appTimes.add(otrosTime ~/ 60000);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 250,
                  child: Stack(
                    children: [
                      SfCircularChart(
                        series: <CircularSeries>[
                          PieSeries<Map<String, Object>, String>(
                            dataSource: List.generate(
                                displayAppNames.length,
                                (index) => {
                                      'name': displayAppNames[index],
                                      'time': appTimes[index],
                                    }),
                            xValueMapper: (Map<String, Object> data, _) =>
                                data['name'] as String,
                            yValueMapper: (Map<String, Object> data, _) =>
                                data['time'] as int,
                            pointColorMapper: (Map<String, Object> data, _) {
                              int index = displayAppNames
                                      .indexOf(data['name'] as String) %
                                  colors.length;
                              return colors[index];
                            },
                            dataLabelMapper: (Map<String, Object> data, _) =>
                                data['name'] as String,
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              textStyle: TextStyle(fontSize: 14),
                              labelPosition: ChartDataLabelPosition.outside,
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey,
                              width: 5.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${_formatTime(totalTime ~/ 60000)}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Top aplicaciones más utilizadas:',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'FFMetaProTitle'),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const ScrollPhysics(),
                  itemCount: usageInfoList.length,
                  itemBuilder: (context, index) {
                    return _buildListTile(usageInfoList[index]);
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }

  //Construle la lista de Aplicaciones mas utilizadas
  Widget _buildListTile(UsageInfo appInfo) {
    return FutureBuilder<String>(
      future: getAppNameFromPackageName(appInfo.packageName!),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        String appName = appInfo.packageName!;
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          appName = snapshot.data!;
        }
        return ListTile(
          leading: getAppIcon(appInfo.packageName!),
          title: Text(appName),
          subtitle: Text(
            'Tiempo de uso: ${_formatTime(int.parse(appInfo.totalTimeInForeground!) ~/ 60000)}',
          ),
        );
      },
    );
  }

  //Funcion obtiene icono de la aplicacion
  Widget getAppIcon(String packageName) {
    return FutureBuilder<Application?>(
      future: getApplicationWithIcon(packageName),
      builder: (BuildContext context, AsyncSnapshot<Application?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 35,
            height: 35,
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          print('Error o sin datos para el paquete: $packageName');
          return Container(
            width: 35,
            height: 35,
            child: Image.asset('assets/images/icono.png'), // Icono por defecto
          );
        } else {
          Application? app = snapshot.data;
          if (app is ApplicationWithIcon) {
            // print('Icono cargado para el paquete: ${app.appName}');
            return Container(
              width: 35,
              height: 35,
              child: Image.memory(app.icon),
            );
          } else {
            print('Sin icono para el paquete: ${app?.appName}');
            return Container(
              width: 35,
              height: 35,
              child:
                  Image.asset('assets/images/icono.png'), // Icono por defecto
            );
          }
        }
      },
    );
  }

  // Funcion obtiene la cedula registrada anteriormente
  Future<void> getCedula() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cedula = prefs.getString('cedula') ?? '**';
    });
  }

  //Funcion de paso para obtener el nombre de la aplicacion, en base a todas las apps
  Future<List<String>> getAppNames(List<UsageInfo> usageInfoList) async {
    List<String> appNames = [];
    for (var appInfo in usageInfoList) {
      String appName = await getAppNameFromPackageName(appInfo.packageName!);
      appNames.add(appName);
    }
    return appNames;
  }

  //Función para obtener el icono de la aplicación
  Future<Application?> getApplicationWithIcon(String packageName) async {
    try {
      Application? app = await DeviceApps.getApp(packageName, true);
      return app;
    } catch (e) {
      print('Error al obtener la aplicación con icono: $e');
      return null;
    }
  }

  //Función para obtener el nombre de la aplicación
  Future<String> getAppNameFromPackageName(String packageName) async {
    try {
      Application? app = await DeviceApps.getApp(packageName);
      return app?.appName ?? packageName;
    } catch (e) {
      print("Error al obtener la aplicación '$packageName': $e");
      return packageName;
    }
  }

  //Funcion que obtiene la hora de mayor uso
  Future<void> _getMostActiveHour(DateTime date) async {
    try {
      // Imprimir la fecha enviada al método
      print('Fecha consumo mayor enviada: $date');

      DateTime endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
      DateTime startDate = DateTime(date.year, date.month, date.day, 0, 0, 0);

      List<UsageInfo> usageStats =
          await UsageStats.queryUsageStats(startDate, endDate);

      Map<int, int> usageByHour = {};
      Map<String, int> usageByApp = {};

      for (var info in usageStats) {
        if (info.firstTimeStamp != null && info.lastTimeStamp != null) {
          DateTime beginTime = DateTime.fromMillisecondsSinceEpoch(
              int.parse(info.firstTimeStamp!));
          DateTime endTime = DateTime.fromMillisecondsSinceEpoch(
              int.parse(info.lastTimeStamp!));
          int hour = beginTime.hour;

          int usageDuration = endTime.difference(beginTime).inMinutes;

          if (usageByHour.containsKey(hour)) {
            usageByHour[hour] = usageByHour[hour]! + usageDuration;
          } else {
            usageByHour[hour] = usageDuration;
          }

          if (usageByApp.containsKey(info.packageName)) {
            usageByApp[info.packageName!] =
                usageByApp[info.packageName]! + usageDuration;
          } else {
            usageByApp[info.packageName!] = usageDuration;
          }
        }
      }

      int maxUsageHour = usageByHour.keys.first;
      for (var hour in usageByHour.keys) {
        if (usageByHour[hour]! > usageByHour[maxUsageHour]!) {
          maxUsageHour = hour;
        }
      }

      setState(() {
        _mostActiveHour = '$maxUsageHour:00 - ${maxUsageHour + 1}:00';
        _usageData = usageByApp.entries
            .map((entry) => {
                  'packageName': entry.key,
                  'usageDuration': entry.value,
                })
            .toList();
      });
    } catch (e) {
      print('Error al obtener los datos de uso: $e');
    }
  }

  //Formatear el tiempo en minutos, horas
  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      return '$hours h $remainingMinutes min';
    }
  }
}
