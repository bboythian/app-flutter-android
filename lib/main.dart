import 'dart:async';
//import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:usage_stats/usage_stats.dart';
//import 'package:app_usage/app_usage.dart'; // Importación de paquetes necesarios
//import 'package:flutter_app_icon/flutter_app_icon.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:device_apps/device_apps.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? storedCedula =
      prefs.getString('cedula'); // Recupera la cédula almacenada

  runApp(MaterialApp(
    home: storedCedula == null
        ? WelcomeScreen()
        : MyApp(
            cedula:
                storedCedula), // Muestra la pantalla de bienvenida si no hay cédula almacenada, de lo contrario, muestra la aplicación principal
    theme: ThemeData(primarySwatch: Colors.blue),
  ));
}

// Pantalla de bienvenida como StatefulWidget
class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _cedulaController =
      TextEditingController(); // Controlador para el campo de texto de la cédula

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenid@'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _cedulaController,
              decoration: const InputDecoration(
                labelText: 'Número de cédula',
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () async {
                String cedula = _cedulaController
                    .text; // Obtiene la cédula ingresada por el usuario
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setString('cedula',
                    cedula); // Almacena la cédula utilizando SharedPreferences
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MyApp(
                          cedula:
                              cedula)), // Navega a la aplicación principal con la cédula como argumento
                );
              },
              child: Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

// Aplicación principal como StatefulWidget
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
  DateTime currentDate = DateTime.now();
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  /*** */
  Future<List<ApplicationWithIcon>>? usageInfoList2;

  @override
  void initState() {
    super.initState();
    initUsage(); // Inicializa la recopilación de datos de uso de la aplicación
    getCedula(); // Obtiene la cédula almacenada al iniciar la aplicación
    ///*** */
    usageInfoList2 = getInstalledAppsWithIcons();

    ///**** */
    Timer.periodic(Duration(minutes: 5), (Timer timer) {
      initUsage(); // Actualiza los datos de uso cada dos minutos
    });
  }

  // Inicializa la recopilación de datos de uso de la aplicación
  Future<void> initUsage() async {
    try {
      UsageStats.grantUsagePermission(); // Solicita permiso de uso
      // Obtener la fecha y hora actual
      startDate = DateTime(
          currentDate.year, currentDate.month, currentDate.day, 0, 0, 1);
      print("INICIO $startDate");
      endDate = DateTime(
          currentDate.year, currentDate.month, currentDate.day, 23, 59, 59);
      print("FIN $endDate");

      List<UsageInfo> usageInfos =
          await UsageStats.queryUsageStats(startDate, endDate);

      // Filtra la lista de datos de uso para incluir solo aplicaciones con un tiempo de uso mayor a 5 minutos
      List<UsageInfo> filteredUsageInfos = usageInfos
          .where((info) =>
              double.parse(info.totalTimeInForeground!) > 5 * 60 * 1000)
          .toList();
      setState(() {
        usageInfoList =
            filteredUsageInfos; //datos filtrados con el tiempo mayor a 5 min
      });
    } catch (err) {
      print("Error: $err");
    }
  }

  // Actualiza los datos de uso al realizar un gesto de actualización
  Future<void> _refresh() async {
    await initUsage();
    // Obtener la fecha actual
    String formattedDate = currentDate.toIso8601String();

    // Obtener los 5 primeros elementos de la lista de datos
    List<UsageInfo> firstFiveUsageInfo = usageInfoList.take(5).toList();

    // Convertir los datos a un formato que se pueda enviar al servidor
    List<Map<String, dynamic>> dataToSend = firstFiveUsageInfo.map((info) {
      return {
        'packageName': getAppNameFromPackageName(info.packageName!),
        'totalTimeInForeground':
            int.parse(info.totalTimeInForeground!) ~/ 60000,
      };
    }).toList();

    // Enviar los datos al servidor
    try {
      var url = Uri.parse(
          'http://10.24.160.139:3000/enviar-datos'); // Reemplaza la dirección IP con la de tu servidor

      var response = await http.post(
        url,
        body: {
          'cedula': widget.cedula,
          'fecha': formattedDate,
          'mayorConsumo': '26', // Obtener la mayor hora de consumo
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

  // Cambia entre las pestañas de la aplicación
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context); // Cierra el menú lateral al cambiar de pestaña
  }

  // Obtiene la cédula almacenada en SharedPreferences
  Future<void> getCedula() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      cedula = prefs.getString('cedula') ??
          '**'; // Muestra "**" si no hay cédula almacenada
    });
  }

  // Actualiza la fecha actual al cambiar de día
  void _updateDate(int days) {
    setState(() {
      currentDate = currentDate.add(Duration(days: days));
      // Limita la fecha actual para evitar fechas futuras o anteriores al inicio del registro
      if (currentDate.isAfter(DateTime.now())) {
        currentDate = DateTime.now();
      } else if (currentDate
          .isBefore(DateTime.now().subtract(Duration(days: 30)))) {
        currentDate = DateTime.now().subtract(Duration(days: 30));
      }
      startDate =
          DateTime(currentDate.year, currentDate.month, currentDate.day);
      endDate =
          DateTime(currentDate.year, currentDate.month, currentDate.day + 1);
    });
    initUsage(); // Actualiza los datos de uso después de cambiar la fecha
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Ciberadiccion",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF002856),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _refresh(); // Actualiza los datos de uso al presionar el botón de actualización
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App-Ciberadiccion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Bienvenido $cedula', // Muestra la cédula del usuario
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text('Home'),
              onTap: () {
                _onTabTapped(
                    0); // Cambia a la pestaña de inicio al seleccionar "Home" en el menú lateral
              },
            ),
            ListTile(
              title: Text('Notificaciones'),
              onTap: () {
                _onTabTapped(
                    1); // Cambia a la pestaña de notificaciones al seleccionar "Notificaciones" en el menú lateral
              },
            ),
            ListTile(
              title: Text('Ajustes'),
              onTap: () {
                _onTabTapped(
                    2); // Cambia a la pestaña de ajustes al seleccionar "Ajustes" en el menú lateral
              },
            ),
          ],
        ),
      ),
      body: _buildBody(), // Construye el cuerpo de la aplicación
    );
  }

  // Construye el cuerpo de la aplicación según la pestaña activa
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHome(); // Construye la pestaña de inicio
      case 1:
        return _buildNotificaciones(); // Construye la pestaña de notificaciones
      case 2:
        return _buildAjustes(); // Construye la pestaña de ajustes
      default:
        return _buildHome(); // Construye la pestaña de inicio por defecto
    }
  }

  // Construye la pestaña de inicio
  Widget _buildHome() {
    usageInfoList.sort((a, b) =>
        int.parse(b.totalTimeInForeground!) -
        int.parse(a
            .totalTimeInForeground!)); // Ordena la lista de aplicaciones por tiempo de uso
    return RefreshIndicator(
      onRefresh:
          _refresh, // Actualiza los datos de uso al realizar un gesto de actualización
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    _updateDate(-1); // Cambia a la fecha anterior
                  },
                ),
                Text(
                  '${currentDate.toLocal()}'
                      .split(' ')[0], // Muestra la fecha actual
                  style: TextStyle(fontSize: 18),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () {
                    _updateDate(1); // Cambia a la fecha siguiente
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            SingleChildScrollView(
              child: _buildPieChart(), // Construye el gráfico de pastel
            ),
          ],
        ),
      ),
    );
  }

  // Construye la pestaña de notificaciones
  Widget _buildNotificaciones() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Configuración de notificaciones',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildNotificacionesList(), // Construye la lista de opciones de notificaciones
        ],
      ),
    );
  }

  // Construye la lista de opciones de notificaciones
  Widget _buildNotificacionesList() {
    return Expanded(
      child: ListView(
        children: [
          _buildNotificacionItem("Notificaciones",
              notificationEnabled), // Construye el elemento de notificación
          _buildNotificacionItem("Limites",
              sugerenciasEnabled), // Construye el elemento de límites
          _buildNotificacionItem("Alertas",
              alternativasEnabled), // Construye el elemento de alertas
        ],
      ),
    );
  }

  // Construye un elemento de notificación
  Widget _buildNotificacionItem(String itemName, bool itemEnabled) {
    return Dismissible(
      key: Key(itemName),
      onDismissed: (direction) {
        print(
            "$itemName deslizado en dirección $direction"); // Imprime la dirección del deslizamiento
      },
      background: Container(
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        child: ListTile(
          title: Text(itemName),
          trailing: Switch(
            value: itemEnabled,
            onChanged: (value) {
              setState(() {
                // Actualiza el estado de la opción de notificación
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

  // Construye la pestaña de ajustes
  Widget _buildAjustes() {
    return Center(
      child: Text(
          'Página de Ajustes'), // Muestra un texto indicando que esta es la página de ajustes
    );
  }

  // Construye el gráfico de pastel para mostrar el uso de aplicaciones
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

    List<UsageInfo> pieChartData = [];
    List<String> appNamesSet = Set<String>().toList();
    List<int> appTimes = [];

    for (int i = 0; i < usageInfoList.length && i < 6; i++) {
      UsageInfo appInfo = usageInfoList[i];
      String appName = getAppNameFromPackageName(appInfo.packageName!);
      if (!appNamesSet.contains(appName)) {
        appNamesSet.add(appName);
        appTimes.add(int.parse(appInfo.totalTimeInForeground!) ~/ 60000);
      }
    }

    List<String> appNames = appNamesSet;

    if (usageInfoList.length > 6) {
      int otrosTime = 0;
      for (int i = 6; i < usageInfoList.length; i++) {
        otrosTime += int.parse(usageInfoList[i].totalTimeInForeground!);
      }
      appNames.add("Otros");
      appTimes.add(otrosTime ~/ 60000);
    }

    return Column(
      children: [
        Container(
          height: 300,
          child: Stack(
            children: [
              SfCircularChart(
                series: <CircularSeries>[
                  PieSeries<String, String>(
                    dataSource: appNames,
                    xValueMapper: (data, _) => data,
                    yValueMapper: (data, _) => appTimes[appNames.indexOf(data)],
                    pointColorMapper: (data, _) {
                      int index = appNames.indexOf(data) % colors.length;
                      return colors[index];
                    },
                    dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        textStyle: TextStyle(fontSize: 16),
                        labelPosition: ChartDataLabelPosition.outside),
                  ),
                ],
              ),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
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
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: ScrollPhysics(),
          itemCount: usageInfoList.length,
          itemBuilder: (context, index) {
            UsageInfo appInfo = usageInfoList[index];
            //String appName = appInfo.packageName.toString(); //para imprimir packetes
            String packageName = appInfo.packageName!;
            String appName = getAppNameFromPackageName(appInfo.packageName!);
            String timeUsed =
                //'${int.parse(appInfo.totalTimeInForeground!) ~/ 60000} min';
                '${_formatTime(int.parse(appInfo.totalTimeInForeground!) ~/ 60000)}';

            return FutureBuilder<Image>(
              future: getAppIcon(
                  packageName), // Obtiene el ícono de la aplicación asincrónicamente
              builder: (BuildContext context, AsyncSnapshot<Image> snapshot) {
                Widget image;
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  // Si el Future se completa y tenemos datos, utilizamos la imagen obtenida.
                  image = snapshot.data!;
                } else if (snapshot.connectionState ==
                        ConnectionState.waiting ||
                    !snapshot.hasData) {
                  // Mientras esperamos o si no hay datos, podemos mostrar un ícono o imagen predeterminados.
                  image = Image.asset(
                      'assets/images/icono.png'); // Asegúrate de tener un ícono predeterminado
                } else {
                  // En caso de error o datos no disponibles, también mostramos un ícono predeterminado.
                  image = Image.asset('assets/images/icono.png');
                } // Usa un contenedor vacío si no hay ícono disponible
                //image = Image.asset('assets/images/icono2.png');
                return ListTile(
                  leading: Container(
                    width: 30, // Define un tamaño para el ícono
                    height: 30,
                    child: image,
                  ),
                  title: Text(appName),
                  subtitle: Text(
                      'Tiempo de uso: ${_formatTime(int.parse(appInfo.totalTimeInForeground!) ~/ 60000)}'),
                );
              },
            );

            /*Icon icon = getAppIcon("com.instagram.android");
            return ListTile(
              leading: icon,
              title: Text(appName),
              subtitle: Text('Tiempo de uso: $timeUsed'),
            );*/
          },
        ),
      ],
    );
  }

  // Método para formatear el tiempo en horas y minutos
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

// Obtiene el nombre de la aplicación a partir del nombre del paquete
String getAppNameFromPackageName(String packageName) {
  List<String> appNames = [
    'Instagram',
    'Facebook',
    'Duolingo',
    'TikTok',
    'Miapp',
    'Youtube',
    'Gmail',
    'Twitch',
    'Twitter',
    'NexusLauncher',
    'Gm',
    'Wellbeing',
    'Vending',
  ];
  String appName = packageName;
  for (String listName in appNames) {
    if (packageName.toLowerCase().contains(listName.toLowerCase())) {
      return listName;
      //return appName.substring(0, 1).toUpperCase() + appName.substring(1);
    }
  }
  return appName; // Devuelve el nombre del paquete si no se encuentra ningún nombre de aplicación correspondiente
}

Future<List<ApplicationWithIcon>> getInstalledAppsWithIcons() async {
  // Obtiene una lista de todas las aplicaciones instaladas (con lanzadores) que incluyen íconos.
  List<Application> apps = await DeviceApps.getInstalledApplications(
    includeAppIcons: true,
    includeSystemApps:
        true, // Cambia a false si no deseas incluir apps del sistema.
    //onlyAppsWithLaunchers: true
  );

  // Filtra la lista para quedarse solo con aplicaciones que tengan íconos.
  return apps.whereType<ApplicationWithIcon>().toList();
}

//CORREGIR LA FUNCION NO ENCUENTRA BIEN LOS ICONOS
Future<Image> getAppIcon(String packageName) async {
  try {
    Application? app = await DeviceApps.getApp(packageName);
    if (app is ApplicationWithIcon) {
      return Image.memory(app.icon);
    }
  } catch (e) {
    print("Error al obtener el ícono de la aplicación: $e");
  }
  // Retorna un ícono predeterminado si no se encuentra el ícono específico o en caso de error
  return Image.asset('assets/images/icono2.png');
}
