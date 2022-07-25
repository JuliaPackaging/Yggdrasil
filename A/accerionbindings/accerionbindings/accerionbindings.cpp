#include "jlcxx/jlcxx.hpp"
#include "jlcxx/stl.hpp"
#include <iostream>
#include <optional>

#include <AccerionSensorAPI/AccerionSensorAPI.h>
// #include <AccerionSensorAPI/AccerionUpdateService.h>

int calibdone = -1;

void funcCB(bool result, std::string msg)
{
    std::cout << "Result: " << result << std::endl;

    calibdone = result;
}


JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{

  mod.map_type<SensorDetails>("SensorDetails");

  mod.map_type<Pose>("Pose");

  mod.map_type<InputPose>("InputPose");

  mod.map_type<StandardDeviation>("StandardDeviation");

  mod.map_type<SerialNumber>("SerialNumber");

  mod.map_type<Address>("Address");

  mod.add_bits<ConnectionType>("ConnectionType", jlcxx::julia_type("CppEnum"));
  mod.set_const("CONNECTION_TCP", ConnectionType::CONNECTION_TCP);
  mod.set_const("CONNECTION_UDP_BROADCAST", ConnectionType::CONNECTION_UDP_BROADCAST);
  mod.set_const("CONNECTION_UDP_UNICAST", ConnectionType::CONNECTION_UDP_UNICAST);
  // mod.set_const("CONNECTION_SET_BY_SENSOR", ConnectionType::CONNECTION_SET_BY_SENSOR);

  mod.add_type<AccerionSensor>("AccerionSensor")
    .constructor<Address, const std::string& , Address , ConnectionType >()
    .method("setPoseAndCovariance", &AccerionSensor::setPoseAndCovariance)
    .method("captureFrame", &AccerionSensor::captureFrame)
    .method("getSerialNumberBlocking", &AccerionSensor::getSerialNumberBlocking);

  // mod.method("setpose",
  // 	     []() {
  // 		   std::cout << "HEllo world!" << std::endl;
  // 	     });

  mod.method("isstoredone",
  	     []() {
	       return calibdone;
  	     });

  mod.method("sendupdate",
	     [](std::string serial, std::string data_path, std::string apikey) {

	       AccerionUpdateServiceManager * uManager = AccerionUpdateServiceManager::getInstance();
	       sleep(2);
	       // std::list<std::pair<Address, std::string>> uServices = uManager->getAllUpdateServices();
	       std::vector<SensorDetails> uServices = uManager->getAllUpdateServices();
	       Address  localAddress;
	       localAddress.first = 0;
	       localAddress.second = 0;
	       localAddress.third = 0;
	       localAddress.fourth = 0;

	       AccerionUpdateService * uService = uManager->getAccerionUpdateServiceBySerial(serial, localAddress);
	       if(uService)
		 {
		   std::cout << "UpdateService Found!" << std::endl;
		   sleep(2);

		   calibdone = -1;

		   uService->sendCalibration(data_path, funcCB, apikey);
		 }
	       else
		 {
		   calibdone = 0;
		   std::cout << "ERROR UpdateService Not Found!" << std::endl;
		 }

	     });

  jlcxx::stl::apply_stl<Address*>(mod);
  jlcxx::stl::apply_stl<AccerionSensor*>(mod);

  mod.method("getAllSensorSNs",
	     []() {
	       AccerionSensorManager* sensorManager = AccerionSensorManager::getInstance();
	       // std::list<std::pair<Address, std::string>> sensorList = sensorManager->getAllSensors();
	       std::vector<SensorDetails> sensorList = sensorManager->getDetectedSensors();
	       std::vector<std::string> result;
	       for (auto p=sensorList.begin(); p!=sensorList.end();p++){
		 result.emplace_back(p->serialNumber);
	       }
	       return result;
	     });

  mod.method("getSensorBySN",
	     [](std::string id) {
	       AccerionSensorManager* sensorManager = AccerionSensorManager::getInstance();
	       std::vector<SensorDetails> sensorList = sensorManager->getDetectedSensors();

	       Address sensorIP, localIP;
	       sensorIP.first = 0;
	       sensorIP.second = 0;
	       sensorIP.third = 0;
	       sensorIP.fourth = 0;

	       std::vector<AccerionSensor*> res(0);
	       for (auto p=sensorList.begin(); p!=sensorList.end();p++){
		 if (p->serialNumber == id) {
		   res.push_back(sensorManager->getAccerionSensorByIPBlocking(p->ipAddress, localIP, ConnectionType::CONNECTION_TCP, 10));
		 }
	       }

	       return res;
	     });

}
