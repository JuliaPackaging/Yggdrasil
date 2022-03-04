#include "jlcxx/jlcxx.hpp"

#include <GeographicLib/Geocentric.hpp>
#include <GeographicLib/Geoid.hpp>
#include <GeographicLib/GravityCircle.hpp>
#include <GeographicLib/GravityModel.hpp>
#include <GeographicLib/MagneticCircle.hpp>
#include <GeographicLib/MagneticModel.hpp>
#include <GeographicLib/Math.hpp>
#include <GeographicLib/NormalGravity.hpp>

using namespace GeographicLib;

JLCXX_MODULE define_julia_module(jlcxx::Module &mod) {
  typedef Math::real real;

  mod.add_type<Geocentric>("Geocentric")
      .constructor<real, real>()
      .method("forward",
              [](const Geocentric &g, real lat, real lon, real h, real &X,
                 real &Y, real &Z) { return g.Forward(lat, lon, h, X, Y, Z); })
      .method("forward",
              [](const Geocentric &g, real lat, real lon, real h, real &X,
                 real &Y, real &Z, std::vector<real> &M) {
                return g.Forward(lat, lon, h, X, Y, Z, M);
              })
      .method("reverse",
              [](const Geocentric &g, real X, real Y, real Z, real &lat,
                 real &lon,
                 real &h) { return g.Reverse(X, Y, Z, lat, lon, h); })
      .method("reverse",
              [](const Geocentric &g, real X, real Y, real Z, real &lat,
                 real &lon, real &h, std::vector<real> &M) {
                return g.Reverse(X, Y, Z, lat, lon, h, M);
              })
      .method("init", &Geocentric::Init)
      .method("equatorial_radius", &Geocentric::EquatorialRadius)
      .method("flattening", &Geocentric::Flattening)
      .method("wgs84_geocentric", &Geocentric::WGS84);

  mod.add_bits<Geoid::convertflag>("ConvertFlag", jlcxx::julia_type("CppEnum"));
  mod.set_const("ELLIPSOIDTOGEOID", Geoid::ELLIPSOIDTOGEOID);
  mod.set_const("NONE", Geoid::NONE);
  mod.set_const("GEOIDTOELLIPSOID", Geoid::GEOIDTOELLIPSOID);

  mod.add_type<Geoid>("Geoid")
      .constructor<const std::string &, const std::string &, bool, bool>()
      .method(&Geoid::operator())
      .method("cache_area", &Geoid::CacheArea)
      .method("cache_all", &Geoid::CacheAll)
      .method("cache_clear", &Geoid::CacheClear)
      .method("convert_height", &Geoid::ConvertHeight)
      .method("description", &Geoid::Description)
      .method("date_time", &Geoid::DateTime)
      .method("geoid_file", &Geoid::GeoidFile)
      .method("geoid_name", &Geoid::GeoidName)
      .method("geoid_directory", &Geoid::GeoidDirectory)
      .method("interpolation", &Geoid::Interpolation)
      .method("max_error", &Geoid::MaxError)
      .method("rms_error", &Geoid::RMSError)
      .method("offset", &Geoid::Offset)
      .method("scale", &Geoid::Scale)
      .method("thread_safe", &Geoid::ThreadSafe)
      .method("cache", &Geoid::Cache)
      .method("cache_west", &Geoid::CacheWest)
      .method("cache_east", &Geoid::CacheEast)
      .method("cache_north", &Geoid::CacheNorth)
      .method("cache_south", &Geoid::CacheSouth)
      .method("equatorial_radius", &Geoid::EquatorialRadius)
      .method("flattening", &Geoid::Flattening)
      .method("default_geoid_path", &Geoid::DefaultGeoidPath)
      .method("default_geoid_name", &Geoid::DefaultGeoidName);

  mod.add_type<NormalGravity>("NormalGravity")
      .constructor<real, real, real, real, bool>()
      .method("surface_gravity", &NormalGravity::SurfaceGravity)
      .method("gravity", &NormalGravity::Gravity)
      .method("u", &NormalGravity::U)
      .method("v0", &NormalGravity::V0)
      .method("phi", &NormalGravity::Phi)
      .method("init", &NormalGravity::Init)
      .method("equatorial_radius", &NormalGravity::EquatorialRadius)
      .method("mass_constant", &NormalGravity::MassConstant)
      .method("dynamical_form_factor", &NormalGravity::DynamicalFormFactor)
      .method("angular_velocity", &NormalGravity::AngularVelocity)
      .method("flattening", &NormalGravity::Flattening)
      .method("equatorial_gravity", &NormalGravity::EquatorialGravity)
      .method("polar_gravity", &NormalGravity::PolarGravity)
      .method("gravity_flattening", &NormalGravity::GravityFlattening)
      .method("surface_potential", &NormalGravity::SurfacePotential)
      .method("earth", &NormalGravity::Earth)
      .method("wgs84_normal_gravity", &NormalGravity::WGS84)
      .method("grs80_normal_gravity", &NormalGravity::GRS80)
      .method("j2_to_flattening", &NormalGravity::J2ToFlattening)
      .method("flattening_to_j2", &NormalGravity::FlatteningToJ2);

  mod.add_type<GravityCircle>("GravityCircle")
      .method("gravity", &GravityCircle::Gravity)
      .method("disturbance", &GravityCircle::Disturbance)
      .method("geoid_height", &GravityCircle::GeoidHeight)
      .method("spherical_anomaly", &GravityCircle::SphericalAnomaly)
      .method("w", [](const GravityCircle &g, real lon, real &gX, real &gY,
                      real &gZ) { return g.W(lon, gX, gY, gZ); })
      .method("v", [](const GravityCircle &g, real lon, real &GX, real &GY,
                      real &GZ) { return g.V(lon, GX, GY, GZ); })
      .method("t",
              [](const GravityCircle &g, real lon, real &deltaX, real &deltaY,
                 real &deltaZ) { return g.T(lon, deltaX, deltaY, deltaZ); })
      .method("t", [](const GravityCircle &g, real lon) { return g.T(lon); })
      .method("init", &GravityCircle::Init)
      .method("equatorial_radius", &GravityCircle::EquatorialRadius)
      .method("flattening", &GravityCircle::Flattening)
      .method("latitude", &GravityCircle::Latitude)
      .method("height", &GravityCircle::Height)
      .method("capabilities",
              [](const GravityCircle &g) { return g.Capabilities(); })
      .method("capabilities", [](const GravityCircle &g, unsigned testcaps) {
        return g.Capabilities(testcaps);
      });

  mod.add_type<GravityModel>("GravityModel")
      .constructor<const std::string &, const std::string &, int, int>()
      .method("gravity", &GravityModel::Gravity)
      .method("disturbance", &GravityModel::Disturbance)
      .method("geoid_height", &GravityModel::GeoidHeight)
      .method("spherical_anomaly", &GravityModel::SphericalAnomaly)
      .method("w", &GravityModel::W)
      .method("v", &GravityModel::V)
      .method("t",
              [](const GravityModel &g, real X, real Y, real Z, real &deltaX,
                 real &deltaY,
                 real &deltaZ) { return g.T(X, Y, Z, deltaX, deltaY, deltaZ); })
      .method("t", [](const GravityModel &g, real X, real Y,
                      real Z) { return g.T(X, Y, Z); })
      .method("u", &GravityModel::U)
      .method("phi", &GravityModel::Phi)
      .method("circle", &GravityModel::Circle)
      .method("reference_ellipsoid", &GravityModel::ReferenceEllipsoid)
      .method("description", &GravityModel::Description)
      .method("date_time", &GravityModel::DateTime)
      .method("gravity_file", &GravityModel::GravityFile)
      .method("gravity_model_name", &GravityModel::GravityModelName)
      .method("gravity_model_directory", &GravityModel::GravityModelDirectory)
      .method("equatorial_radius", &GravityModel::EquatorialRadius)
      .method("mass_constant", &GravityModel::MassConstant)
      .method("reference_mass_constant", &GravityModel::ReferenceMassConstant)
      .method("angular_velocity", &GravityModel::AngularVelocity)
      .method("flattening", &GravityModel::Flattening)
      .method("degree", &GravityModel::Degree)
      .method("order", &GravityModel::Order)
      .method("default_gravity_path", &GravityModel::DefaultGravityPath)
      .method("default_gravity_name", &GravityModel::DefaultGravityName);

  mod.add_type<MagneticCircle>("MagneticCircle")
      .method([](const MagneticCircle &m, real lon, real &Bx, real &By,
                 real &Bz) { return m(lon, Bx, By, Bz); })
      .method([](const MagneticCircle &m, real lon, real &Bx, real &By,
                 real &Bz, real &Bxt, real &Byt,
                 real &Bzt) { return m(lon, Bx, By, Bz, Bxt, Byt, Bzt); })
      .method("field_geocentric",
              [](const MagneticCircle &m, real lon, real &BX, real &BY,
                 real &BZ, real &BXt, real &BYt, real &BZt) {
                return m.FieldGeocentric(lon, BX, BY, BZ, BXt, BYt, BZt);
              })
      .method("init", &MagneticCircle::Init)
      .method("equatorial_radius", &MagneticCircle::EquatorialRadius)
      .method("flattening", &MagneticCircle::Flattening)
      .method("latitude", &MagneticCircle::Latitude)
      .method("height", &MagneticCircle::Height)
      .method("time", &MagneticCircle::Time);

  mod.add_type<MagneticModel>("MagneticModel")
      .constructor<const std::string &, const std::string &, const Geocentric &,
                   int, int>()
      .method([](const MagneticModel &m, real t, real lat, real lon, real h,
                 real &Bx, real &By,
                 real &Bz) { return m(t, lat, lon, h, Bx, By, Bz); })
      .method([](const MagneticModel &m, real t, real lat, real lon, real h,
                 real &Bx, real &By, real &Bz, real &Bxt, real &Byt,
                 real &Bzt) {
        return m(t, lat, lon, h, Bx, By, Bz, Bxt, Byt, Bzt);
      })
      .method("circle", &MagneticModel::Circle)
      .method("field_geocentric", &MagneticModel::FieldGeocentric)
      .method("field_components",
              [](const MagneticModel &m, real Bx, real By, real Bz, real &H,
                 real &F, real &D,
                 real &I) { return m.FieldComponents(Bx, By, Bz, H, F, D, I); })
      .method("field_components",
              [](const MagneticModel &m, real Bx, real By, real Bz, real Bxt,
                 real Byt, real Bzt, real &H, real &F, real &D, real &I,
                 real &Ht, real &Ft, real &Dt, real &It) {
                return m.FieldComponents(Bx, By, Bz, Bxt, Byt, Bzt, H, F, D, I,
                                         Ht, Ft, Dt, It);
              })
      .method("description", &MagneticModel::Description)
      .method("date_time", &MagneticModel::DateTime)
      .method("magnetic_file", &MagneticModel::MagneticFile)
      .method("magnetic_model_name", &MagneticModel::MagneticModelName)
      .method("magnetic_model_directory",
              &MagneticModel::MagneticModelDirectory)
      .method("min_height", &MagneticModel::MinHeight)
      .method("max_height", &MagneticModel::MaxHeight)
      .method("min_time", &MagneticModel::MinTime)
      .method("max_time", &MagneticModel::MaxTime)
      .method("equitorial_radius", &MagneticModel::EquatorialRadius)
      .method("flattening", &MagneticModel::Flattening)
      .method("degree", &MagneticModel::Degree)
      .method("order", &MagneticModel::Order)
      .method("default_magnetic_path", &MagneticModel::DefaultMagneticPath)
      .method("default_magnetic_name", &MagneticModel::DefaultMagneticName);
}
