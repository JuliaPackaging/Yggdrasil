/**
 * PROPOSAL Julia Bindings
 *
 * CxxWrap bindings for PROPOSAL functionality.
 */

#include "jlcxx/jlcxx.hpp"
#include "jlcxx/array.hpp"

#include "PROPOSAL/PROPOSAL.h"

using namespace PROPOSAL;

// SuperType specializations for CxxWrap inheritance upcasting
namespace jlcxx {
    // ParticleDef subtypes
    template<> struct SuperType<MuMinusDef> { typedef ParticleDef type; };
    template<> struct SuperType<MuPlusDef> { typedef ParticleDef type; };
    template<> struct SuperType<EMinusDef> { typedef ParticleDef type; };
    template<> struct SuperType<EPlusDef> { typedef ParticleDef type; };
    template<> struct SuperType<TauMinusDef> { typedef ParticleDef type; };
    template<> struct SuperType<TauPlusDef> { typedef ParticleDef type; };
    template<> struct SuperType<GammaDef> { typedef ParticleDef type; };
    template<> struct SuperType<Pi0Def> { typedef ParticleDef type; };
    template<> struct SuperType<PiMinusDef> { typedef ParticleDef type; };
    template<> struct SuperType<PiPlusDef> { typedef ParticleDef type; };
    template<> struct SuperType<K0Def> { typedef ParticleDef type; };
    template<> struct SuperType<KMinusDef> { typedef ParticleDef type; };
    template<> struct SuperType<KPlusDef> { typedef ParticleDef type; };
    template<> struct SuperType<NuEDef> { typedef ParticleDef type; };
    template<> struct SuperType<NuEBarDef> { typedef ParticleDef type; };
    template<> struct SuperType<NuMuDef> { typedef ParticleDef type; };
    template<> struct SuperType<NuMuBarDef> { typedef ParticleDef type; };
    template<> struct SuperType<NuTauDef> { typedef ParticleDef type; };
    template<> struct SuperType<NuTauBarDef> { typedef ParticleDef type; };
    template<> struct SuperType<StauMinusDef> { typedef ParticleDef type; };
    template<> struct SuperType<StauPlusDef> { typedef ParticleDef type; };
    template<> struct SuperType<MonopoleDef> { typedef ParticleDef type; };
    template<> struct SuperType<SMPMinusDef> { typedef ParticleDef type; };
    template<> struct SuperType<SMPPlusDef> { typedef ParticleDef type; };

    // Geometry subtypes
    template<> struct SuperType<Sphere> { typedef Geometry type; };
    template<> struct SuperType<Cylinder> { typedef Geometry type; };
    template<> struct SuperType<Box> { typedef Geometry type; };

    // Axis subtypes
    template<> struct SuperType<CartesianAxis> { typedef Axis type; };
    template<> struct SuperType<RadialAxis> { typedef Axis type; };

    // Density subtypes
    template<> struct SuperType<Density_homogeneous> { typedef Density_distr type; };
    template<> struct SuperType<Density_exponential> { typedef Density_distr type; };
    template<> struct SuperType<Density_polynomial> { typedef Density_distr type; };
    template<> struct SuperType<Density_splines> { typedef Density_distr type; };

    // Spline subtypes
    template<> struct SuperType<Linear_Spline> { typedef Spline type; };
    template<> struct SuperType<Cubic_Spline> { typedef Spline type; };

    // Disable mirrored type for Polynom and Spline types
    template<> struct IsMirroredType<Polynom> : std::false_type {};
    template<> struct IsMirroredType<Spline> : std::false_type {};
    template<> struct IsMirroredType<Linear_Spline> : std::false_type {};
    template<> struct IsMirroredType<Cubic_Spline> : std::false_type {};

    // DecayChannel subtypes
    template<> struct SuperType<StableChannel> { typedef DecayChannel type; };
    template<> struct SuperType<LeptonicDecayChannelApprox> { typedef DecayChannel type; };
    template<> struct SuperType<LeptonicDecayChannel> { typedef LeptonicDecayChannelApprox type; };
    template<> struct SuperType<TwoBodyPhaseSpace> { typedef DecayChannel type; };
    template<> struct SuperType<ManyBodyPhaseSpace> { typedef DecayChannel type; };

    // Component subtypes
    template<> struct SuperType<Components::Hydrogen> { typedef Component type; };
    template<> struct SuperType<Components::Carbon> { typedef Component type; };
    template<> struct SuperType<Components::Nitrogen> { typedef Component type; };
    template<> struct SuperType<Components::Oxygen> { typedef Component type; };
    template<> struct SuperType<Components::Sodium> { typedef Component type; };
    template<> struct SuperType<Components::Magnesium> { typedef Component type; };
    template<> struct SuperType<Components::Sulfur> { typedef Component type; };
    template<> struct SuperType<Components::Chlorine> { typedef Component type; };
    template<> struct SuperType<Components::Argon> { typedef Component type; };
    template<> struct SuperType<Components::Potassium> { typedef Component type; };
    template<> struct SuperType<Components::Calcium> { typedef Component type; };
    template<> struct SuperType<Components::Iron> { typedef Component type; };
    template<> struct SuperType<Components::Copper> { typedef Component type; };
    template<> struct SuperType<Components::Lead> { typedef Component type; };
    template<> struct SuperType<Components::Uranium> { typedef Component type; };
    template<> struct SuperType<Components::StandardRock> { typedef Component type; };
    template<> struct SuperType<Components::FrejusRock> { typedef Component type; };

    // Vector3D subtypes
    template<> struct SuperType<Cartesian3D> { typedef Vector3D type; };
    template<> struct SuperType<Spherical3D> { typedef Vector3D type; };

    // Scattering subtypes
    template<> struct SuperType<multiple_scattering::Highland> { typedef multiple_scattering::Parametrization type; };
    template<> struct SuperType<multiple_scattering::HighlandIntegral> { typedef multiple_scattering::Highland type; };
    template<> struct SuperType<multiple_scattering::Moliere> { typedef multiple_scattering::Parametrization type; };
    template<> struct SuperType<multiple_scattering::MoliereInterpol> { typedef multiple_scattering::Moliere type; };
    // Crosssection parametrization subtypes
    template<> struct SuperType<crosssection::Bremsstrahlung> { typedef crosssection::Parametrization<Component> type; };
    template<> struct SuperType<crosssection::EpairProduction> { typedef crosssection::Parametrization<Component> type; };
    template<> struct SuperType<crosssection::EpairProductionRhoIntegral> { typedef crosssection::EpairProduction type; };
    template<> struct SuperType<crosssection::Photonuclear> { typedef crosssection::Parametrization<Component> type; };
    template<> struct SuperType<crosssection::PhotoRealPhotonAssumption> { typedef crosssection::Photonuclear type; };
    template<> struct SuperType<crosssection::PhotoQ2Integral> { typedef crosssection::Photonuclear type; };
    template<> struct SuperType<crosssection::MupairProduction> { typedef crosssection::Parametrization<Component> type; };
    template<> struct SuperType<crosssection::MupairProductionRhoIntegral> { typedef crosssection::MupairProduction type; };
    template<> struct SuperType<crosssection::WeakInteraction> { typedef crosssection::Parametrization<Component> type; };
    template<> struct SuperType<crosssection::Compton> { typedef crosssection::Parametrization<Component> type; };
    template<> struct SuperType<crosssection::PhotoPairProduction> { typedef crosssection::Parametrization<Component> type; };
    template<> struct SuperType<crosssection::PhotoMuPairProduction> { typedef crosssection::Parametrization<Component> type; };
    template<> struct SuperType<crosssection::Ionization> { typedef crosssection::Parametrization<Medium> type; };

    // Concrete brems
    template<> struct SuperType<crosssection::BremsKelnerKokoulinPetrukhin> { typedef crosssection::Bremsstrahlung type; };
    template<> struct SuperType<crosssection::BremsPetrukhinShestakov> { typedef crosssection::Bremsstrahlung type; };
    template<> struct SuperType<crosssection::BremsCompleteScreening> { typedef crosssection::Bremsstrahlung type; };
    template<> struct SuperType<crosssection::BremsAndreevBezrukovBugaev> { typedef crosssection::Bremsstrahlung type; };
    template<> struct SuperType<crosssection::BremsSandrockSoedingreksoRhode> { typedef crosssection::Bremsstrahlung type; };
    template<> struct SuperType<crosssection::BremsElectronScreening> { typedef crosssection::Bremsstrahlung type; };

    // Concrete epair
    template<> struct SuperType<crosssection::EpairKelnerKokoulinPetrukhin> { typedef crosssection::EpairProductionRhoIntegral type; };
    template<> struct SuperType<crosssection::EpairSandrockSoedingreksoRhode> { typedef crosssection::EpairProductionRhoIntegral type; };
    template<> struct SuperType<crosssection::EpairForElectronPositron> { typedef crosssection::EpairProductionRhoIntegral type; };

    // Concrete photo real
    template<> struct SuperType<crosssection::PhotoZeus> { typedef crosssection::PhotoRealPhotonAssumption type; };
    template<> struct SuperType<crosssection::PhotoBezrukovBugaev> { typedef crosssection::PhotoRealPhotonAssumption type; };
    template<> struct SuperType<crosssection::PhotoKokoulin> { typedef crosssection::PhotoRealPhotonAssumption type; };
    template<> struct SuperType<crosssection::PhotoRhode> { typedef crosssection::PhotoRealPhotonAssumption type; };

    // Concrete photo Q2
    template<> struct SuperType<crosssection::PhotoAbramowiczLevinLevyMaor91> { typedef crosssection::PhotoQ2Integral type; };
    template<> struct SuperType<crosssection::PhotoAbramowiczLevinLevyMaor97> { typedef crosssection::PhotoQ2Integral type; };
    template<> struct SuperType<crosssection::PhotoButkevichMikheyev> { typedef crosssection::PhotoQ2Integral type; };
    template<> struct SuperType<crosssection::PhotoRenoSarcevicSu> { typedef crosssection::PhotoQ2Integral type; };
    template<> struct SuperType<crosssection::PhotoAbtFT> { typedef crosssection::PhotoQ2Integral type; };
    template<> struct SuperType<crosssection::PhotoBlockDurandHa> { typedef crosssection::PhotoQ2Integral type; };

    // Concrete mupair
    template<> struct SuperType<crosssection::MupairKelnerKokoulinPetrukhin> { typedef crosssection::MupairProductionRhoIntegral type; };

    // Concrete ionization
    template<> struct SuperType<crosssection::IonizBetheBlochRossi> { typedef crosssection::Ionization type; };
    template<> struct SuperType<crosssection::IonizBergerSeltzerBhabha> { typedef crosssection::Ionization type; };
    template<> struct SuperType<crosssection::IonizBergerSeltzerMoller> { typedef crosssection::Ionization type; };

    // Concrete compton
    template<> struct SuperType<crosssection::ComptonKleinNishina> { typedef crosssection::Compton type; };

    // Concrete weak
    template<> struct SuperType<crosssection::WeakCooperSarkarMertsch> { typedef crosssection::WeakInteraction type; };

    // Concrete annihilation
    template<> struct SuperType<crosssection::AnnihilationHeitler> { typedef crosssection::Annihilation type; };

    // Concrete photopair
    template<> struct SuperType<crosssection::PhotoPairTsai> { typedef crosssection::PhotoPairProduction type; };
    template<> struct SuperType<crosssection::PhotoPairKochMotz> { typedef crosssection::PhotoPairProduction type; };

    // Concrete photomupair
    template<> struct SuperType<crosssection::PhotoMuPairBurkhardtKelnerKokoulin> { typedef crosssection::PhotoMuPairProduction type; };

    // ParametrizationDirect subtypes
    template<> struct SuperType<crosssection::Annihilation> { typedef crosssection::ParametrizationDirect type; };
    template<> struct SuperType<crosssection::Photoproduction> { typedef crosssection::ParametrizationDirect type; };
    template<> struct SuperType<crosssection::Photoeffect> { typedef crosssection::ParametrizationDirect type; };

    // Concrete photoproduction
    template<> struct SuperType<crosssection::PhotoproductionZeus> { typedef crosssection::Photoproduction type; };
    template<> struct SuperType<crosssection::PhotoproductionBezrukovBugaev> { typedef crosssection::Photoproduction type; };
    template<> struct SuperType<crosssection::PhotoproductionCaldwell> { typedef crosssection::Photoproduction type; };
    template<> struct SuperType<crosssection::PhotoproductionKokoulin> { typedef crosssection::Photoproduction type; };
    template<> struct SuperType<crosssection::PhotoproductionRhode> { typedef crosssection::Photoproduction type; };
    template<> struct SuperType<crosssection::PhotoproductionHeck> { typedef crosssection::Photoproduction type; };
    template<> struct SuperType<crosssection::PhotoproductionHeckC7Shadowing> { typedef crosssection::Photoproduction type; };

    // Concrete photoeffect
    template<> struct SuperType<crosssection::PhotoeffectSauter> { typedef crosssection::Photoeffect type; };

    // Shadow effect subtypes
    template<> struct SuperType<crosssection::ShadowDuttaRenoSarcevicSeckel> { typedef crosssection::ShadowEffect type; };
    template<> struct SuperType<crosssection::ShadowButkevichMikheyev> { typedef crosssection::ShadowEffect type; };

    // Disable mirrored type for KinematicLimits
    template<> struct IsMirroredType<crosssection::KinematicLimits> : std::false_type {};
}

// Module-level storage for cross section vectors (avoids exposing std::vector to CxxWrap)
static std::vector<std::vector<std::shared_ptr<CrossSectionBase>>> g_crosssection_sets;

JLCXX_MODULE define_julia_module(jlcxx::Module& mod) {

    // ========== Math Types ==========

    // Vector3D base class
    mod.add_type<Vector3D>("Vector3D");

    // Cartesian3D
    mod.add_type<Cartesian3D>("Cartesian3D", jlcxx::julia_base_type<Vector3D>())
        .constructor<>()
        .constructor<double, double, double>()
        .method("get_x", &Cartesian3D::GetX)
        .method("get_y", &Cartesian3D::GetY)
        .method("get_z", &Cartesian3D::GetZ)
        .method("set_x", &Cartesian3D::SetX)
        .method("set_y", &Cartesian3D::SetY)
        .method("set_z", &Cartesian3D::SetZ)
        .method("magnitude", &Cartesian3D::magnitude)
        .method("normalize", &Cartesian3D::normalize)
        .method("deflect", &Cartesian3D::deflect);

    // Cartesian3D operator helpers
    mod.method("cartesian3d_add", [](const Cartesian3D& a, const Cartesian3D& b) {
        return Cartesian3D(a.GetX() + b.GetX(), a.GetY() + b.GetY(), a.GetZ() + b.GetZ());
    });
    mod.method("cartesian3d_subtract", [](const Cartesian3D& a, const Cartesian3D& b) {
        return Cartesian3D(a.GetX() - b.GetX(), a.GetY() - b.GetY(), a.GetZ() - b.GetZ());
    });
    mod.method("cartesian3d_scale", [](const Cartesian3D& a, double s) {
        return Cartesian3D(a.GetX() * s, a.GetY() * s, a.GetZ() * s);
    });
    mod.method("cartesian3d_dot", [](const Cartesian3D& a, const Cartesian3D& b) {
        return a.GetX() * b.GetX() + a.GetY() * b.GetY() + a.GetZ() * b.GetZ();
    });
    mod.method("cartesian3d_negate", [](const Cartesian3D& a) {
        return Cartesian3D(-a.GetX(), -a.GetY(), -a.GetZ());
    });
    mod.method("cartesian3d_get_spherical", [](const Cartesian3D& c, jlcxx::ArrayRef<double> arr) {
        auto s = c.GetSphericalCoordinates();
        arr[0] = s[0]; arr[1] = s[1]; arr[2] = s[2];
    });

    // Spherical3D
    mod.add_type<Spherical3D>("Spherical3D", jlcxx::julia_base_type<Vector3D>())
        .constructor<>()
        .constructor<double, double, double>()
        .constructor<const Vector3D&>()
        .method("get_radius", &Spherical3D::GetRadius)
        .method("get_azimuth", &Spherical3D::GetAzimuth)
        .method("get_zenith", &Spherical3D::GetZenith)
        .method("set_radius", &Spherical3D::SetRadius)
        .method("set_azimuth", &Spherical3D::SetAzimuth)
        .method("set_zenith", &Spherical3D::SetZenith)
        .method("magnitude", &Spherical3D::magnitude)
        .method("normalize", &Spherical3D::normalize);

    // UnitSphericalVector
    mod.add_type<UnitSphericalVector>("UnitSphericalVector")
        .constructor<>()
        .constructor<double, double>()
        .method("get_zenith", [](const UnitSphericalVector& u) { return u.zenith; })
        .method("get_azimuth", [](const UnitSphericalVector& u) { return u.azimuth; });

    // ========== Particle Types ==========

    // ParticleDef struct
    mod.add_type<ParticleDef>("ParticleDef")
        .method("get_name", [](const ParticleDef& p) { return std::string(p.name); })
        .method("get_mass", [](const ParticleDef& p) { return p.mass; })
        .method("get_lifetime", [](const ParticleDef& p) { return p.lifetime; })
        .method("get_charge", [](const ParticleDef& p) { return p.charge; })
        .method("get_particle_type", [](const ParticleDef& p) { return p.particle_type; });

    // Predefined particle definitions
    mod.add_type<MuMinusDef>("MuMinusDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<MuPlusDef>("MuPlusDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<EMinusDef>("EMinusDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<EPlusDef>("EPlusDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<TauMinusDef>("TauMinusDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<TauPlusDef>("TauPlusDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<GammaDef>("GammaDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<Pi0Def>("Pi0Def", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<PiMinusDef>("PiMinusDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<PiPlusDef>("PiPlusDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<K0Def>("K0Def", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<KMinusDef>("KMinusDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<KPlusDef>("KPlusDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<NuEDef>("NuEDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<NuEBarDef>("NuEBarDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<NuMuDef>("NuMuDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<NuMuBarDef>("NuMuBarDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<NuTauDef>("NuTauDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<NuTauBarDef>("NuTauBarDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<StauMinusDef>("StauMinusDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<StauPlusDef>("StauPlusDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<MonopoleDef>("MonopoleDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<SMPMinusDef>("SMPMinusDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();
    mod.add_type<SMPPlusDef>("SMPPlusDef", jlcxx::julia_base_type<ParticleDef>())
        .constructor<>();

    // ParticleState
    mod.add_type<ParticleState>("ParticleState")
        .constructor<>()
        .method("get_type", [](const ParticleState& p) { return static_cast<int>(p.type); })
        .method("get_position", [](const ParticleState& p) { return Cartesian3D(p.position); })
        .method("get_direction", [](const ParticleState& p) { return Cartesian3D(p.direction); })
        .method("get_energy", [](const ParticleState& p) { return p.energy; })
        .method("get_time", [](const ParticleState& p) { return p.time; })
        .method("get_propagated_distance", [](const ParticleState& p) { return p.propagated_distance; });

    // Factory function for ParticleState
    mod.method("make_particle_state", [](int type, double x, double y, double z,
                                         double dx, double dy, double dz,
                                         double energy, double time, double prop_dist) {
        ParticleState state;
        state.type = type;
        state.position = Cartesian3D(x, y, z);
        state.direction = Cartesian3D(dx, dy, dz);
        state.energy = energy;
        state.time = time;
        state.propagated_distance = prop_dist;
        return state;
    });

    // ========== Energy Cut Settings ==========

    mod.add_type<EnergyCutSettings>("EnergyCutSettings")
        .constructor<double, double, bool>()
        .method("get_ecut", &EnergyCutSettings::GetEcut)
        .method("get_vcut", &EnergyCutSettings::GetVcut)
        .method("get_cont_rand", &EnergyCutSettings::GetContRand)
        .method("cut", [](const EnergyCutSettings& c, double energy) {
            return c.GetCut(energy);
        });

    // ========== Component ==========

    mod.add_type<Component>("Component")
        .constructor<std::string, double, double, double>()
        .method("get_name", &Component::GetName)
        .method("get_nuc_charge", &Component::GetNucCharge)
        .method("get_atomic_num", &Component::GetAtomicNum)
        .method("get_atom_in_molecule", &Component::GetAtomInMolecule)
        .method("get_log_constant", &Component::GetLogConstant)
        .method("get_b_prime", &Component::GetBPrime)
        .method("get_average_nucleon_weight", &Component::GetAverageNucleonWeight)
        .method("get_wood_saxon", &Component::GetWoodSaxon)
        .method("get_hash", [](const Component& c) { return static_cast<int64_t>(c.GetHash()); });

    mod.method("get_component_for_hash", [](int64_t hash) {
        return Component::GetComponentForHash(static_cast<size_t>(hash));
    });

    // Named Components
    mod.add_type<Components::Hydrogen>("ComponentHydrogen", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::Carbon>("ComponentCarbon", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::Nitrogen>("ComponentNitrogen", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::Oxygen>("ComponentOxygen", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::Sodium>("ComponentSodium", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::Magnesium>("ComponentMagnesium", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::Sulfur>("ComponentSulfur", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::Chlorine>("ComponentChlorine", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::Argon>("ComponentArgon", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::Potassium>("ComponentPotassium", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::Calcium>("ComponentCalcium", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::Iron>("ComponentIron", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::Copper>("ComponentCopper", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::Lead>("ComponentLead", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::Uranium>("ComponentUranium", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::StandardRock>("ComponentStandardRock", jlcxx::julia_base_type<Component>())
        .constructor<double>();
    mod.add_type<Components::FrejusRock>("ComponentFrejusRock", jlcxx::julia_base_type<Component>())
        .constructor<double>();

    // ========== Medium ==========

    mod.add_type<Medium>("Medium")
        .method("get_name", &Medium::GetName)
        .method("get_mass_density", &Medium::GetMassDensity)
        .method("get_mol_density", &Medium::GetMolDensity)
        .method("get_I", &Medium::GetI)
        .method("get_C", &Medium::GetC)
        .method("get_A", &Medium::GetA)
        .method("get_M", &Medium::GetM)
        .method("get_X0", &Medium::GetX0)
        .method("get_X1", &Medium::GetX1)
        .method("get_D0", &Medium::GetD0)
        .method("get_radiation_length", &Medium::GetRadiationLength)
        .method("get_MM", &Medium::GetMM)
        .method("get_sum_charge", &Medium::GetSumCharge)
        .method("get_ZA", &Medium::GetZA)
        .method("get_num_components", &Medium::GetNumComponents)
        .method("get_sum_nucleons", &Medium::GetSumNucleons)
        .method("get_hash", [](const Medium& m) { return static_cast<int64_t>(m.GetHash()); })
        .method("get_component", [](const Medium& m, int i) {
            auto components = m.GetComponents();
            return components.at(i);
        })
        .method("get_components_size", [](const Medium& m) {
            return static_cast<int>(m.GetComponents().size());
        });

    // Medium factory function
    mod.method("create_medium", [](const std::string& name) {
        auto ptr = CreateMedium(name);
        Medium result = *ptr;
        return result;
    });

    // Named Media (registered as standalone types — Medium is not polymorphic)
    mod.method("create_water", []() { return Medium(Water()); });
    mod.method("create_ice", []() { return Medium(Ice()); });
    mod.method("create_salt", []() { return Medium(Salt()); });
    mod.method("create_calcium_carbonate", []() { return Medium(CalciumCarbonate()); });
    mod.method("create_standard_rock", []() { return Medium(StandardRock()); });
    mod.method("create_frejus_rock", []() { return Medium(FrejusRock()); });
    mod.method("create_iron_medium", []() { return Medium(Iron()); });
    mod.method("create_hydrogen_medium", []() { return Medium(Hydrogen()); });
    mod.method("create_lead_medium", []() { return Medium(Lead()); });
    mod.method("create_copper_medium", []() { return Medium(Copper()); });
    mod.method("create_uranium_medium", []() { return Medium(Uranium()); });
    mod.method("create_paraffin", []() { return Medium(Paraffin()); });
    mod.method("create_air", []() { return Medium(Air()); });
    mod.method("create_liquid_argon", []() { return Medium(LiquidArgon()); });
    mod.method("create_antares_water", []() { return Medium(AntaresWater()); });
    mod.method("create_cascadia_basin_water", []() { return Medium(CascadiaBasinWater()); });

    // PDG2001/PDG2020 factory functions
    mod.method("create_pdg2001_water", []() { return Medium(PDG2001::Water()); });
    mod.method("create_pdg2001_ice", []() { return Medium(PDG2001::Ice()); });
    mod.method("create_pdg2020_water", []() { return Medium(PDG2020::Water()); });
    mod.method("create_pdg2020_ice", []() { return Medium(PDG2020::Ice()); });

    // ========== Geometry ==========

    mod.add_type<Geometry>("Geometry")
        .method("is_inside", [](const Geometry& g, const Cartesian3D& pos, const Cartesian3D& dir) {
            return g.IsInside(pos, dir);
        })
        .method("is_infront", [](const Geometry& g, const Cartesian3D& pos, const Cartesian3D& dir) {
            return g.IsInfront(pos, dir);
        })
        .method("is_behind", [](const Geometry& g, const Cartesian3D& pos, const Cartesian3D& dir) {
            return g.IsBehind(pos, dir);
        })
        .method("is_entering", [](const Geometry& g, const Cartesian3D& pos, const Cartesian3D& dir) {
            return g.IsEntering(pos, dir);
        })
        .method("is_leaving", [](const Geometry& g, const Cartesian3D& pos, const Cartesian3D& dir) {
            return g.IsLeaving(pos, dir);
        })
        .method("distance_to_border_first", [](const Geometry& g, const Cartesian3D& pos, const Cartesian3D& dir) {
            return g.DistanceToBorder(pos, dir).first;
        })
        .method("distance_to_border_second", [](const Geometry& g, const Cartesian3D& pos, const Cartesian3D& dir) {
            return g.DistanceToBorder(pos, dir).second;
        })
        .method("distance_to_closest_approach", [](const Geometry& g, const Cartesian3D& pos, const Cartesian3D& dir) {
            return g.DistanceToClosestApproach(pos, dir);
        })
        .method("get_position", [](const Geometry& g) { return Cartesian3D(g.GetPosition()); })
        .method("get_geometry_name", &Geometry::GetName)
        .method("get_hierarchy", &Geometry::GetHierarchy)
        .method("set_hierarchy", &Geometry::SetHierarchy);

    mod.add_type<Sphere>("Sphere", jlcxx::julia_base_type<Geometry>())
        .constructor<Cartesian3D, double, double>()
        .method("get_radius", &Sphere::GetRadius)
        .method("get_inner_radius", &Sphere::GetInnerRadius);

    mod.add_type<Cylinder>("Cylinder", jlcxx::julia_base_type<Geometry>())
        .constructor<Cartesian3D, double, double, double>()
        .method("get_radius", &Cylinder::GetRadius)
        .method("get_inner_radius", &Cylinder::GetInnerRadius)
        .method("get_z", &Cylinder::GetZ);

    mod.add_type<Box>("Box", jlcxx::julia_base_type<Geometry>())
        .constructor<Cartesian3D, double, double, double>()
        .method("get_x", &Box::GetX)
        .method("get_y", &Box::GetY)
        .method("get_z", &Box::GetZ);

    // ========== Density Distributions ==========

    mod.add_type<Axis>("Axis");

    mod.add_type<CartesianAxis>("CartesianAxis", jlcxx::julia_base_type<Axis>())
        .constructor<Cartesian3D, Cartesian3D>();

    mod.add_type<RadialAxis>("RadialAxis", jlcxx::julia_base_type<Axis>())
        .constructor<Cartesian3D>();

    mod.add_type<Density_distr>("DensityDistribution")
        .method("evaluate", [](const Density_distr& d, const Cartesian3D& pos) {
            return d.Evaluate(pos);
        })
        .method("integrate", [](const Density_distr& d, const Cartesian3D& pos, const Cartesian3D& dir, double l) {
            return d.Integrate(pos, dir, l);
        })
        .method("calculate", [](const Density_distr& d, const Cartesian3D& pos, const Cartesian3D& dir, double dist) {
            return d.Calculate(pos, dir, dist);
        })
        .method("correct", [](const Density_distr& d, const Cartesian3D& pos, const Cartesian3D& dir, double res, double dist_to_border) {
            return d.Correct(pos, dir, res, dist_to_border);
        });

    mod.add_type<Density_homogeneous>("DensityHomogeneous", jlcxx::julia_base_type<Density_distr>())
        .constructor<double>();

    mod.add_type<Density_exponential>("DensityExponential", jlcxx::julia_base_type<Density_distr>())
        .constructor<const Axis&, double, double, double>();

    // ========== Cross Sections ==========

    mod.add_type<CrossSectionBase>("CrossSectionBase")
        .method("calculate_dEdx", [](CrossSectionBase& cs, double energy) {
            return cs.CalculatedEdx(energy);
        })
        .method("calculate_dE2dx", [](CrossSectionBase& cs, double energy) {
            return cs.CalculatedE2dx(energy);
        })
        .method("calculate_dNdx", [](CrossSectionBase& cs, double energy) {
            return cs.CalculatedNdx(energy);
        })
        .method("calculate_stochastic_loss", [](CrossSectionBase& cs, size_t target, double energy, double rnd) {
            return cs.CalculateStochasticLoss(target, energy, rnd);
        })
        .method("get_interaction_type", [](const CrossSectionBase& cs) {
            return static_cast<int>(cs.GetInteractionType());
        })
        .method("get_parametrization_name", [](const CrossSectionBase& cs) {
            return cs.GetParametrizationName();
        })
        .method("get_lower_energy_lim", [](const CrossSectionBase& cs) {
            return cs.GetLowerEnergyLim();
        });

    // Factory: create cross sections for a particle/medium combo
    mod.method("create_crosssections", [](const ParticleDef& pdef, const Medium& medium,
                                          double ecut, double vcut, bool cont_rand, bool interpolate) {
        auto cuts = std::make_shared<const EnergyCutSettings>(ecut, vcut, cont_rand);
        auto cross = GetStdCrossSections(pdef, medium, cuts, interpolate);
        int handle = static_cast<int>(g_crosssection_sets.size());
        g_crosssection_sets.push_back(std::move(cross));
        return handle;
    });

    mod.method("crosssection_count", [](int handle) {
        return static_cast<int>(g_crosssection_sets.at(handle).size());
    });

    mod.method("crosssection_at", [](int handle, int i) -> CrossSectionBase& {
        return *g_crosssection_sets.at(handle).at(i);
    });

    mod.method("free_crosssections", [](int handle) {
        if (handle >= 0 && handle < static_cast<int>(g_crosssection_sets.size())) {
            g_crosssection_sets[handle].clear();
        }
    });

    // ========== Decay ==========

    mod.add_type<DecayChannel>("DecayChannel")
        .method("get_channel_name", [](const DecayChannel& dc) {
            return dc.GetName();
        });

    mod.add_type<StableChannel>("StableChannel", jlcxx::julia_base_type<DecayChannel>())
        .constructor<>();

    mod.add_type<LeptonicDecayChannelApprox>("LeptonicDecayChannelApprox", jlcxx::julia_base_type<DecayChannel>())
        .constructor<const ParticleDef&, const ParticleDef&, const ParticleDef&>();

    mod.add_type<LeptonicDecayChannel>("LeptonicDecayChannel", jlcxx::julia_base_type<LeptonicDecayChannelApprox>())
        .constructor<const ParticleDef&, const ParticleDef&, const ParticleDef&>();

    mod.add_type<TwoBodyPhaseSpace>("TwoBodyPhaseSpace", jlcxx::julia_base_type<DecayChannel>())
        .constructor<const ParticleDef&, const ParticleDef&>();

    mod.add_type<ManyBodyPhaseSpace>("ManyBodyPhaseSpace", jlcxx::julia_base_type<DecayChannel>())
        .method("set_uniform_sampling", &ManyBodyPhaseSpace::SetUniformSampling);

    // ManyBodyPhaseSpace factory (takes particle defs as arguments)
    mod.method("create_many_body_phase_space_2", [](const ParticleDef& d1, const ParticleDef& d2) {
        std::vector<std::shared_ptr<const ParticleDef>> daughters;
        daughters.push_back(std::make_shared<const ParticleDef>(d1));
        daughters.push_back(std::make_shared<const ParticleDef>(d2));
        return ManyBodyPhaseSpace(daughters);
    });
    mod.method("create_many_body_phase_space_3", [](const ParticleDef& d1, const ParticleDef& d2, const ParticleDef& d3) {
        std::vector<std::shared_ptr<const ParticleDef>> daughters;
        daughters.push_back(std::make_shared<const ParticleDef>(d1));
        daughters.push_back(std::make_shared<const ParticleDef>(d2));
        daughters.push_back(std::make_shared<const ParticleDef>(d3));
        return ManyBodyPhaseSpace(daughters);
    });

    // DecayChannel.Decay — fill arrays with decay product data
    mod.method("decay_channel_decay_to_arrays", [](DecayChannel& dc, const ParticleDef& pdef, const ParticleState& state,
                                                    jlcxx::ArrayRef<int> types_arr,
                                                    jlcxx::ArrayRef<double> energies_arr,
                                                    jlcxx::ArrayRef<double> dx_arr,
                                                    jlcxx::ArrayRef<double> dy_arr,
                                                    jlcxx::ArrayRef<double> dz_arr) -> int {
        auto products = dc.Decay(pdef, state);
        int n = std::min(static_cast<int>(products.size()), static_cast<int>(types_arr.size()));
        for (int i = 0; i < n; ++i) {
            types_arr[i] = static_cast<int>(products[i].type);
            energies_arr[i] = products[i].energy;
            dx_arr[i] = products[i].direction.GetX();
            dy_arr[i] = products[i].direction.GetY();
            dz_arr[i] = products[i].direction.GetZ();
        }
        return static_cast<int>(products.size());
    });

    mod.add_type<DecayTable>("DecayTable")
        .constructor<>()
        .method("add_channel", [](DecayTable& dt, double br, const DecayChannel& dc) {
            dt.addChannel(br, dc);
        })
        .method("set_stable", &DecayTable::SetStable)
        .method("set_uniform_sampling", &DecayTable::SetUniformSampling)
        .method("select_channel", [](DecayTable& dt, double rnd) -> DecayChannel& {
            return dt.SelectChannel(rnd);
        });

    // ========== ParticleDef::Builder ==========

    mod.add_type<ParticleDef::Builder>("ParticleDefBuilder")
        .constructor<>()
        .method("set_name", &ParticleDef::Builder::SetName)
        .method("set_mass", &ParticleDef::Builder::SetMass)
        .method("set_low", &ParticleDef::Builder::SetLow)
        .method("set_lifetime", &ParticleDef::Builder::SetLifetime)
        .method("set_charge", &ParticleDef::Builder::SetCharge)
        .method("set_decay_table", &ParticleDef::Builder::SetDecayTable)
        .method("set_particle_type", &ParticleDef::Builder::SetParticleType)
        .method("set_particle_def", &ParticleDef::Builder::SetParticleDef)
        .method("set_weak_partner", &ParticleDef::Builder::SetWeakPartner)
        .method("build", &ParticleDef::Builder::build);

    // ========== Secondaries (Track) ==========

    mod.add_type<StochasticLoss>("StochasticLoss")
        .method("get_type", [](const StochasticLoss& l) { return l.type; })
        .method("get_energy", [](const StochasticLoss& l) { return l.energy; })
        .method("get_parent_particle_energy", [](const StochasticLoss& l) { return l.parent_particle_energy; })
        .method("get_position", [](const StochasticLoss& l) { return l.position; })
        .method("get_direction", [](const StochasticLoss& l) { return l.direction; })
        .method("get_time", [](const StochasticLoss& l) { return l.time; })
        .method("get_propagated_distance", [](const StochasticLoss& l) { return l.propagated_distance; })
        .method("get_target_hash", [](const StochasticLoss& l) { return static_cast<int64_t>(l.target_hash); });

    mod.add_type<ContinuousLoss>("ContinuousLoss")
        .method("get_type", [](const ContinuousLoss& l) { return l.type; })
        .method("get_energy", [](const ContinuousLoss& l) { return l.energy; })
        .method("get_parent_particle_energy", [](const ContinuousLoss& l) { return l.parent_particle_energy; })
        .method("get_start_position", [](const ContinuousLoss& l) { return l.start_position; })
        .method("get_end_position", [](const ContinuousLoss& l) { return l.end_position; })
        .method("get_direction_initial", [](const ContinuousLoss& l) { return l.direction_initial; })
        .method("get_direction_final", [](const ContinuousLoss& l) { return l.direction_final; })
        .method("get_time_initial", [](const ContinuousLoss& l) { return l.time_initial; })
        .method("get_time_final", [](const ContinuousLoss& l) { return l.time_final; });

    mod.add_type<Secondaries>("Secondaries")
        .method("track_size", [](const Secondaries& s) { return s.GetTrack().size(); })
        .method("get_track_state", [](const Secondaries& s, size_t i) {
            return s.GetTrack().at(i);
        })
        .method("get_initial_state", &Secondaries::GetInitialState)
        .method("get_final_state", &Secondaries::GetFinalState)
        .method("get_track_length", &Secondaries::GetTrackLength)
        .method("get_track_energies_array", [](const Secondaries& s, jlcxx::ArrayRef<double> arr) {
            auto energies = s.GetTrackEnergies();
            for (size_t i = 0; i < energies.size() && i < arr.size(); ++i) {
                arr[i] = energies[i];
            }
            return energies.size();
        })
        .method("get_track_times_array", [](const Secondaries& s, jlcxx::ArrayRef<double> arr) {
            auto times = s.GetTrackTimes();
            for (size_t i = 0; i < times.size() && i < arr.size(); ++i) {
                arr[i] = times[i];
            }
            return times.size();
        })
        .method("get_track_propagated_distances_array", [](const Secondaries& s, jlcxx::ArrayRef<double> arr) {
            auto dists = s.GetTrackPropagatedDistances();
            for (size_t i = 0; i < dists.size() && i < arr.size(); ++i) {
                arr[i] = dists[i];
            }
            return dists.size();
        })
        .method("has_decay", [](const Secondaries& s) -> bool {
            auto types = s.GetTrackTypes();
            for (auto t : types) {
                if (t == InteractionType::Decay) return true;
            }
            return false;
        })
        .method("get_total_continuous_energy_loss", [](const Secondaries& s) -> double {
            auto losses = s.GetContinuousLosses();
            double total = 0.0;
            for (const auto& loss : losses) {
                total += loss.energy;
            }
            return total;
        })
        .method("get_decay_products_to_array", [](const Secondaries& s,
                    jlcxx::ArrayRef<int> types_arr,
                    jlcxx::ArrayRef<double> energies_arr,
                    jlcxx::ArrayRef<double> dx_arr,
                    jlcxx::ArrayRef<double> dy_arr,
                    jlcxx::ArrayRef<double> dz_arr) -> int {
            try {
                auto products = s.GetDecayProducts();
                int n = std::min(static_cast<int>(products.size()),
                                 static_cast<int>(types_arr.size()));
                for (int i = 0; i < n; ++i) {
                    types_arr[i] = static_cast<int>(products[i].type);
                    energies_arr[i] = products[i].energy;
                    auto dir = products[i].direction;
                    dx_arr[i] = dir.GetX();
                    dy_arr[i] = dir.GetY();
                    dz_arr[i] = dir.GetZ();
                }
                return static_cast<int>(products.size());
            } catch (...) {
                return 0;
            }
        })
        .method("get_state_for_energy", &Secondaries::GetStateForEnergy)
        .method("get_state_for_distance", &Secondaries::GetStateForDistance)
        .method("get_stochastic_losses_count", [](const Secondaries& s) {
            return static_cast<int>(s.GetStochasticLosses().size());
        })
        .method("get_stochastic_loss_at", [](const Secondaries& s, int i) {
            return s.GetStochasticLosses().at(i);
        })
        .method("get_continuous_losses_count", [](const Secondaries& s) {
            return static_cast<int>(s.GetContinuousLosses().size());
        })
        .method("get_continuous_loss_at", [](const Secondaries& s, int i) {
            return s.GetContinuousLosses().at(i);
        })
        .method("get_track_positions_count", [](const Secondaries& s) {
            return static_cast<int>(s.GetTrackPositions().size());
        })
        .method("get_track_position_at", [](const Secondaries& s, int i) {
            return s.GetTrackPositions().at(i);
        })
        .method("get_track_directions_count", [](const Secondaries& s) {
            return static_cast<int>(s.GetTrackDirections().size());
        })
        .method("get_track_direction_at", [](const Secondaries& s, int i) {
            return s.GetTrackDirections().at(i);
        })
        .method("get_track_types_array", [](const Secondaries& s, jlcxx::ArrayRef<int> arr) {
            auto types = s.GetTrackTypes();
            for (size_t i = 0; i < types.size() && i < arr.size(); ++i) {
                arr[i] = static_cast<int>(types[i]);
            }
            return static_cast<int>(types.size());
        })
        .method("get_target_hashes_array", [](const Secondaries& s, jlcxx::ArrayRef<int64_t> arr) {
            auto hashes = s.GetTargetHashes();
            for (size_t i = 0; i < hashes.size() && i < arr.size(); ++i) {
                arr[i] = static_cast<int64_t>(hashes[i]);
            }
            return static_cast<int>(hashes.size());
        })
        .method("hit_geometry", [](const Secondaries& s, const Geometry& g) {
            return s.HitGeometry(g);
        })
        .method("get_elost", [](const Secondaries& s, const Geometry& g) {
            return s.GetELost(g);
        })
        .method("get_entry_point", [](const Secondaries& s, const Geometry& g) -> ParticleState {
            auto ptr = s.GetEntryPoint(g);
            if (ptr) return *ptr;
            return ParticleState();
        })
        .method("has_entry_point", [](const Secondaries& s, const Geometry& g) -> bool {
            return s.GetEntryPoint(g) != nullptr;
        })
        .method("get_exit_point", [](const Secondaries& s, const Geometry& g) -> ParticleState {
            auto ptr = s.GetExitPoint(g);
            if (ptr) return *ptr;
            return ParticleState();
        })
        .method("has_exit_point", [](const Secondaries& s, const Geometry& g) -> bool {
            return s.GetExitPoint(g) != nullptr;
        })
        .method("get_stochastic_losses_in_geometry_count", [](const Secondaries& s, const Geometry& g) {
            return static_cast<int>(s.GetStochasticLosses(g).size());
        })
        .method("get_stochastic_loss_in_geometry_at", [](const Secondaries& s, const Geometry& g, int i) {
            return s.GetStochasticLosses(g).at(i);
        })
        .method("get_track_in_geometry_count", [](const Secondaries& s, const Geometry& g) {
            return static_cast<int>(s.GetTrack(g).size());
        })
        .method("get_track_in_geometry_at", [](const Secondaries& s, const Geometry& g, int i) {
            return s.GetTrack(g).at(i);
        });

    // ========== Scattering ==========

    // ScatteringOffset
    mod.add_type<multiple_scattering::ScatteringOffset>("ScatteringOffset")
        .method("get_sx", [](const multiple_scattering::ScatteringOffset& s) { return s.sx; })
        .method("get_sy", [](const multiple_scattering::ScatteringOffset& s) { return s.sy; })
        .method("get_tx", [](const multiple_scattering::ScatteringOffset& s) { return s.tx; })
        .method("get_ty", [](const multiple_scattering::ScatteringOffset& s) { return s.ty; });

    // Multiple scattering base
    mod.add_type<multiple_scattering::Parametrization>("MultipleScattering")
        .method("scatter", [](multiple_scattering::Parametrization& p, double grammage,
                              double ei, double ef, double r1, double r2, double r3, double r4) {
            std::array<double, 4> rnd = {r1, r2, r3, r4};
            return p.CalculateRandomAngle(grammage, ei, ef, rnd);
        })
        .method("scattering_angle", [](multiple_scattering::Parametrization& p,
                                       double grammage, double ei, double ef, double rnd) {
            return p.CalculateScatteringAngle(grammage, ei, ef, rnd);
        })
        .method("scattering_angle_2d", [](multiple_scattering::Parametrization& p,
                                          double grammage, double ei, double ef, double r1, double r2) {
            return p.CalculateScatteringAngle2D(grammage, ei, ef, r1, r2);
        });

    // Highland
    mod.add_type<multiple_scattering::Highland>("Highland",
        jlcxx::julia_base_type<multiple_scattering::Parametrization>())
        .constructor<const ParticleDef&, const Medium&>()
        .method("calculate_theta0", [](multiple_scattering::Highland& h,
                                       double grammage, double ei, double ef) {
            return h.CalculateTheta0(grammage, ei, ef);
        });

    // Moliere
    mod.add_type<multiple_scattering::Moliere>("Moliere",
        jlcxx::julia_base_type<multiple_scattering::Parametrization>())
        .constructor<const ParticleDef&, const Medium&>();

    // MoliereInterpol
    mod.add_type<multiple_scattering::MoliereInterpol>("MoliereInterpol",
        jlcxx::julia_base_type<multiple_scattering::Moliere>())
        .constructor<const ParticleDef&, const Medium&>();

    // HighlandIntegral (needs Displacement from cross sections)
    mod.add_type<multiple_scattering::HighlandIntegral>("HighlandIntegral",
        jlcxx::julia_base_type<multiple_scattering::Highland>());

    // HighlandIntegral factory (takes cross-section handle)
    mod.method("create_highland_integral", [](const ParticleDef& p, const Medium& m,
                                               int cross_handle, bool interpolate) {
        auto& cross = g_crosssection_sets.at(cross_handle);
        auto ms = make_highland_integral(p, m, cross, interpolate);
        // Convert unique_ptr to shared_ptr for CxxWrap
        return std::shared_ptr<multiple_scattering::Parametrization>(std::move(ms));
    });

    // Stochastic deflection base
    mod.add_type<stochastic_deflection::Parametrization>("StochasticDeflection")
        .method("required_random_numbers", [](const stochastic_deflection::Parametrization& p) {
            return static_cast<int>(p.RequiredRandomNumbers());
        })
        .method("get_interaction_type_sd", [](const stochastic_deflection::Parametrization& p) {
            return static_cast<int>(p.GetInteractionType());
        });

    // Stochastic deflection factory by name
    mod.method("make_stochastic_deflection", [](const std::string& name,
                                                 const ParticleDef& p, const Medium& m) {
        auto sd = make_stochastic_deflection(name, p, m);
        return std::shared_ptr<stochastic_deflection::Parametrization>(std::move(sd));
    });

    // Scattering
    mod.add_type<Scattering>("Scattering");

    // ScatteringMultiplier (no type registration — template constructors not compatible with CxxWrap)
    // Use create_scattering_multiplier factory function instead.

    // Scattering factory: ms only
    mod.method("create_scattering_ms_only", [](const std::string& ms_name,
                                                const ParticleDef& p, const Medium& m) {
        auto ms = make_multiple_scattering(ms_name, p, m);
        std::vector<std::unique_ptr<stochastic_deflection::Parametrization>> sd;
        return std::make_shared<Scattering>(std::move(ms), std::move(sd));
    });

    // Scattering factory: ms + single stochastic deflection by name
    mod.method("create_scattering_with_sd", [](const std::string& ms_name,
                                                const ParticleDef& p, const Medium& m,
                                                const std::string& sd_name) -> std::shared_ptr<Scattering> {
        auto sd_ptr = make_stochastic_deflection(sd_name, p, m);
        auto ms = make_multiple_scattering(ms_name, p, m);
        std::vector<std::unique_ptr<stochastic_deflection::Parametrization>> sd;
        sd.push_back(std::move(sd_ptr));
        return std::make_shared<Scattering>(std::move(ms), std::move(sd));
    });

    // make_scattering from enum-style names (combines ms type + sd types)
    mod.method("create_scattering_by_types", [](const std::string& ms_name,
                                                 const ParticleDef& p, const Medium& m,
                                                 jlcxx::ArrayRef<int> sd_interaction_types) {
        auto ms = make_multiple_scattering(ms_name, p, m);
        std::vector<std::unique_ptr<stochastic_deflection::Parametrization>> sd;
        for (size_t i = 0; i < sd_interaction_types.size(); ++i) {
            auto t = static_cast<InteractionType>(sd_interaction_types[i]);
            sd.push_back(make_default_stochastic_deflection(t, p, m));
        }
        return std::make_shared<Scattering>(std::move(ms), std::move(sd));
    });

    // ScatteringMultiplier factory
    mod.method("create_scattering_multiplier", [](const std::string& ms_name,
                                                    const ParticleDef& p, const Medium& m,
                                                    double ms_multiplier,
                                                    jlcxx::ArrayRef<int> sd_interaction_types,
                                                    jlcxx::ArrayRef<double> sd_multipliers) {
        auto ms = make_multiple_scattering(ms_name, p, m);
        std::vector<std::unique_ptr<stochastic_deflection::Parametrization>> sd;
        std::vector<std::pair<InteractionType, double>> sd_mult;
        for (size_t i = 0; i < sd_interaction_types.size(); ++i) {
            auto t = static_cast<InteractionType>(sd_interaction_types[i]);
            sd.push_back(make_default_stochastic_deflection(t, p, m));
            sd_mult.push_back({t, sd_multipliers[i]});
        }
        return std::shared_ptr<Scattering>(std::make_shared<ScatteringMultiplier>(std::move(ms), std::move(sd), ms_multiplier, sd_mult));
    });

    // ========== Propagation Utility Types ==========

    // Displacement
    mod.add_type<Displacement>("Displacement")
        .method("solve_track_integral", [](Displacement& d, double upper, double lower) {
            return d.SolveTrackIntegral(upper, lower);
        })
        .method("upper_limit_track_integral", [](Displacement& d, double energy, double distance) {
            return d.UpperLimitTrackIntegral(energy, distance);
        })
        .method("get_lower_lim", [](const Displacement& d) {
            return d.GetLowerLim();
        });

    // Interaction
    mod.add_type<Interaction>("Interaction")
        .method("energy_interaction", [](Interaction& inter, double energy, double rnd) {
            return inter.EnergyInteraction(energy, rnd);
        })
        .method("energy_integral", [](Interaction& inter, double ei, double ef) {
            return inter.EnergyIntegral(ei, ef);
        })
        .method("mean_free_path", [](Interaction& inter, double energy) {
            return inter.MeanFreePath(energy);
        });

    // Interaction::Rate — expose via module-level accessors
    mod.method("interaction_rates", [](Interaction& inter, double energy,
                                       jlcxx::ArrayRef<double> rate_arr,
                                       jlcxx::ArrayRef<int64_t> hash_arr) {
        auto rates = inter.Rates(energy);
        int n = std::min(static_cast<int>(rates.size()), static_cast<int>(rate_arr.size()));
        for (int i = 0; i < n; ++i) {
            rate_arr[i] = rates[i].rate;
            hash_arr[i] = static_cast<int64_t>(rates[i].comp_hash);
        }
        return static_cast<int>(rates.size());
    });

    // Interaction::Loss — sample_loss returns (type, comp_hash, v_loss)
    mod.method("interaction_sample_loss", [](Interaction& inter, double energy, double rnd,
                                             jlcxx::ArrayRef<double> rate_values,
                                             jlcxx::ArrayRef<int64_t> rate_hashes,
                                             int n_rates,
                                             jlcxx::ArrayRef<double> result) {
        // Reconstruct rates vector
        auto rates = inter.Rates(energy);
        auto loss = inter.SampleLoss(energy, rates, rnd);
        result[0] = static_cast<double>(static_cast<int>(loss.type));
        result[1] = static_cast<double>(loss.comp_hash);
        result[2] = loss.v_loss;
    });

    // ContRand
    mod.add_type<ContRand>("ContRand")
        .method("variance", [](ContRand& cr, double ei, double ef) {
            return cr.Variance(ei, ef);
        })
        .method("energy_randomize", [](ContRand& cr, double ei, double ef, double rnd, double min_energy) {
            return cr.EnergyRandomize(ei, ef, rnd, min_energy);
        });

    // Decay (utility)
    mod.add_type<Decay>("DecayCalc")
        .method("energy_decay", [](Decay& d, double energy, double rnd, double density) {
            return d.EnergyDecay(energy, rnd, density);
        });

    // Time
    mod.add_type<Time>("TimeCalc")
        .method("time_elapsed", [](Time& t, double ei, double ef, double grammage, double density) {
            return t.TimeElapsed(ei, ef, grammage, density);
        });

    // PropagationUtility::Collection
    mod.add_type<PropagationUtility::Collection>("PropagationUtilityCollection")
        .constructor<>();

    // Collection setter methods via module-level functions
    mod.method("set_interaction!", [](PropagationUtility::Collection& c, std::shared_ptr<Interaction> inter) {
        c.interaction_calc = inter;
    });
    mod.method("set_displacement!", [](PropagationUtility::Collection& c, std::shared_ptr<Displacement> disp) {
        c.displacement_calc = disp;
    });
    mod.method("set_time!", [](PropagationUtility::Collection& c, std::shared_ptr<Time> t) {
        c.time_calc = t;
    });
    mod.method("set_scattering!", [](PropagationUtility::Collection& c, std::shared_ptr<Scattering> s) {
        c.scattering = s;
    });
    mod.method("set_decay!", [](PropagationUtility::Collection& c, std::shared_ptr<Decay> d) {
        c.decay_calc = d;
    });
    mod.method("set_cont_rand!", [](PropagationUtility::Collection& c, std::shared_ptr<ContRand> cr) {
        c.cont_rand = cr;
    });

    // PropagationUtility
    mod.add_type<PropagationUtility>("PropagationUtility")
        .method("energy_stochasticloss", [](PropagationUtility& pu, double energy, double rnd,
                                            jlcxx::ArrayRef<double> result) {
            auto loss = pu.EnergyStochasticloss(energy, rnd);
            result[0] = static_cast<double>(static_cast<int>(loss.type));
            result[1] = static_cast<double>(loss.comp_hash);
            result[2] = loss.v_loss;
        })
        .method("energy_distance", [](PropagationUtility& pu, double ei, double dist) {
            return pu.EnergyDistance(ei, dist);
        })
        .method("length_continuous", [](PropagationUtility& pu, double ei, double ef) {
            return pu.LengthContinuous(ei, ef);
        });

    mod.method("create_propagation_utility", [](const PropagationUtility::Collection& coll) {
        return PropagationUtility(coll);
    });

    // Propagation utility factory functions
    mod.method("make_displacement", [](int cross_handle, bool interpolate) {
        auto& cross = g_crosssection_sets.at(cross_handle);
        auto disp = make_displacement(cross, interpolate);
        return std::shared_ptr<Displacement>(std::move(disp));
    });

    mod.method("make_interaction", [](int cross_handle, bool interpolate) {
        auto& cross = g_crosssection_sets.at(cross_handle);
        auto inter = make_interaction(cross, interpolate);
        return std::shared_ptr<Interaction>(std::move(inter));
    });

    mod.method("make_contrand", [](int cross_handle, bool interpolate) {
        auto& cross = g_crosssection_sets.at(cross_handle);
        auto cr = make_contrand(cross, interpolate);
        return std::shared_ptr<ContRand>(std::move(cr));
    });

    mod.method("make_decay_calc", [](int cross_handle, const ParticleDef& pdef, bool interpolate) {
        auto& cross = g_crosssection_sets.at(cross_handle);
        auto d = make_decay(cross, pdef, interpolate);
        return std::shared_ptr<Decay>(std::move(d));
    });

    mod.method("make_time_calc", [](int cross_handle, const ParticleDef& pdef, bool interpolate) {
        auto& cross = g_crosssection_sets.at(cross_handle);
        auto t = make_time(cross, pdef, interpolate);
        return std::shared_ptr<Time>(std::move(t));
    });

    mod.method("make_time_approximate", []() -> std::shared_ptr<Time> {
        return std::make_shared<ApproximateTimeBuilder>();
    });

    // ========== Sector-based Propagator ==========

    mod.add_type<Propagator>("Propagator")
        .method("propagate", [](Propagator& prop, const ParticleState& initial,
                               double max_distance, double min_energy) {
            return prop.Propagate(initial, max_distance, min_energy);
        })
        .method("propagate_with_hierarchy", [](Propagator& prop, const ParticleState& initial,
                               double max_distance, double min_energy, int hierarchy_condition) {
            return prop.Propagate(initial, max_distance, min_energy, static_cast<unsigned int>(hierarchy_condition));
        });

    // Factory functions for Propagator with each particle type
    mod.method("create_propagator_muminus", [](const std::string& config_path) {
        return Propagator(MuMinusDef(), config_path);
    });
    mod.method("create_propagator_muplus", [](const std::string& config_path) {
        return Propagator(MuPlusDef(), config_path);
    });
    mod.method("create_propagator_eminus", [](const std::string& config_path) {
        return Propagator(EMinusDef(), config_path);
    });
    mod.method("create_propagator_eplus", [](const std::string& config_path) {
        return Propagator(EPlusDef(), config_path);
    });
    mod.method("create_propagator_tauminus", [](const std::string& config_path) {
        return Propagator(TauMinusDef(), config_path);
    });
    mod.method("create_propagator_tauplus", [](const std::string& config_path) {
        return Propagator(TauPlusDef(), config_path);
    });
    mod.method("create_propagator_gamma", [](const std::string& config_path) {
        return Propagator(GammaDef(), config_path);
    });

    // Generic propagator from ParticleDef + config
    mod.method("create_propagator", [](const ParticleDef& pdef, const std::string& config_path) {
        return Propagator(pdef, config_path);
    });

    // Sector-based propagator: single sector (overloads for each geometry type)
    mod.method("make_propagator_single_sector_sphere", [](const ParticleDef& pdef,
                                                    const Sphere& geo,
                                                    const Density_homogeneous& density,
                                                    const PropagationUtility::Collection& coll) {
        auto geo_ptr = std::make_shared<const Sphere>(geo);
        auto dens_ptr = std::make_shared<const Density_homogeneous>(density);
        auto utility = PropagationUtility(coll);
        std::vector<Sector> sectors;
        sectors.emplace_back(geo_ptr, std::move(utility), dens_ptr);
        return Propagator(pdef, std::move(sectors));
    });
    mod.method("make_propagator_single_sector_cylinder", [](const ParticleDef& pdef,
                                                    const Cylinder& geo,
                                                    const Density_homogeneous& density,
                                                    const PropagationUtility::Collection& coll) {
        auto geo_ptr = std::make_shared<const Cylinder>(geo);
        auto dens_ptr = std::make_shared<const Density_homogeneous>(density);
        auto utility = PropagationUtility(coll);
        std::vector<Sector> sectors;
        sectors.emplace_back(geo_ptr, std::move(utility), dens_ptr);
        return Propagator(pdef, std::move(sectors));
    });
    mod.method("make_propagator_single_sector_box", [](const ParticleDef& pdef,
                                                    const Box& geo,
                                                    const Density_homogeneous& density,
                                                    const PropagationUtility::Collection& coll) {
        auto geo_ptr = std::make_shared<const Box>(geo);
        auto dens_ptr = std::make_shared<const Density_homogeneous>(density);
        auto utility = PropagationUtility(coll);
        std::vector<Sector> sectors;
        sectors.emplace_back(geo_ptr, std::move(utility), dens_ptr);
        return Propagator(pdef, std::move(sectors));
    });

    // Exponential density variants
    mod.method("make_propagator_single_sector_sphere_exp", [](const ParticleDef& pdef,
                                                    const Sphere& geo,
                                                    const Density_exponential& density,
                                                    const PropagationUtility::Collection& coll) {
        auto geo_ptr = std::make_shared<const Sphere>(geo);
        auto dens_ptr = std::make_shared<const Density_exponential>(density);
        auto utility = PropagationUtility(coll);
        std::vector<Sector> sectors;
        sectors.emplace_back(geo_ptr, std::move(utility), dens_ptr);
        return Propagator(pdef, std::move(sectors));
    });
    mod.method("make_propagator_single_sector_cylinder_exp", [](const ParticleDef& pdef,
                                                    const Cylinder& geo,
                                                    const Density_exponential& density,
                                                    const PropagationUtility::Collection& coll) {
        auto geo_ptr = std::make_shared<const Cylinder>(geo);
        auto dens_ptr = std::make_shared<const Density_exponential>(density);
        auto utility = PropagationUtility(coll);
        std::vector<Sector> sectors;
        sectors.emplace_back(geo_ptr, std::move(utility), dens_ptr);
        return Propagator(pdef, std::move(sectors));
    });
    mod.method("make_propagator_single_sector_box_exp", [](const ParticleDef& pdef,
                                                    const Box& geo,
                                                    const Density_exponential& density,
                                                    const PropagationUtility::Collection& coll) {
        auto geo_ptr = std::make_shared<const Box>(geo);
        auto dens_ptr = std::make_shared<const Density_exponential>(density);
        auto utility = PropagationUtility(coll);
        std::vector<Sector> sectors;
        sectors.emplace_back(geo_ptr, std::move(utility), dens_ptr);
        return Propagator(pdef, std::move(sectors));
    });

    // Multi-sector propagator using stored sectors
    // Sector storage
    static std::vector<Sector> g_sectors;

    mod.method("clear_sectors", []() { g_sectors.clear(); });

    mod.method("add_sector_sphere_homogeneous", [](const Sphere& geo, const Density_homogeneous& dens,
                                                    const PropagationUtility::Collection& coll) {
        auto geo_ptr = std::make_shared<const Sphere>(geo);
        auto dens_ptr = std::make_shared<const Density_homogeneous>(dens);
        auto utility = PropagationUtility(coll);
        g_sectors.emplace_back(geo_ptr, std::move(utility), dens_ptr);
        return static_cast<int>(g_sectors.size()) - 1;
    });

    mod.method("add_sector_cylinder_homogeneous", [](const Cylinder& geo, const Density_homogeneous& dens,
                                                      const PropagationUtility::Collection& coll) {
        auto geo_ptr = std::make_shared<const Cylinder>(geo);
        auto dens_ptr = std::make_shared<const Density_homogeneous>(dens);
        auto utility = PropagationUtility(coll);
        g_sectors.emplace_back(geo_ptr, std::move(utility), dens_ptr);
        return static_cast<int>(g_sectors.size()) - 1;
    });

    mod.method("add_sector_box_homogeneous", [](const Box& geo, const Density_homogeneous& dens,
                                                 const PropagationUtility::Collection& coll) {
        auto geo_ptr = std::make_shared<const Box>(geo);
        auto dens_ptr = std::make_shared<const Density_homogeneous>(dens);
        auto utility = PropagationUtility(coll);
        g_sectors.emplace_back(geo_ptr, std::move(utility), dens_ptr);
        return static_cast<int>(g_sectors.size()) - 1;
    });

    mod.method("add_sector_sphere_exponential", [](const Sphere& geo, const Density_exponential& dens,
                                                    const PropagationUtility::Collection& coll) {
        auto geo_ptr = std::make_shared<const Sphere>(geo);
        auto dens_ptr = std::make_shared<const Density_exponential>(dens);
        auto utility = PropagationUtility(coll);
        g_sectors.emplace_back(geo_ptr, std::move(utility), dens_ptr);
        return static_cast<int>(g_sectors.size()) - 1;
    });

    mod.method("make_propagator_from_sectors", [](const ParticleDef& pdef) {
        auto prop = Propagator(pdef, std::move(g_sectors));
        g_sectors.clear();
        return prop;
    });

    // ========== Crosssection Parametrizations ==========

    // KinematicLimits struct
    mod.add_type<crosssection::KinematicLimits>("KinematicLimits")
        .method("get_v_min", [](const crosssection::KinematicLimits& kl) { return kl.v_min; })
        .method("get_v_max", [](const crosssection::KinematicLimits& kl) { return kl.v_max; });

    // Parametrization<Component> base
    mod.add_type<crosssection::Parametrization<Component>>("ParametrizationForComponent")
        .method("differential_crosssection", [](const crosssection::Parametrization<Component>& p,
                                                 const ParticleDef& pdef, const Component& comp,
                                                 double energy, double v) {
            return p.DifferentialCrossSection(pdef, comp, energy, v);
        })
        .method("get_kinematic_limits", [](const crosssection::Parametrization<Component>& p,
                                           const ParticleDef& pdef, const Component& comp, double energy) {
            return p.GetKinematicLimits(pdef, comp, energy);
        })
        .method("get_lower_energy_lim_param", [](const crosssection::Parametrization<Component>& p,
                                                  const ParticleDef& pdef) {
            return p.GetLowerEnergyLim(pdef);
        })
        .method("get_hash", [](const crosssection::Parametrization<Component>& p) {
            return static_cast<int64_t>(p.GetHash());
        });

    // Parametrization<Medium> base
    mod.add_type<crosssection::Parametrization<Medium>>("ParametrizationForMedium")
        .method("differential_crosssection", [](const crosssection::Parametrization<Medium>& p,
                                                 const ParticleDef& pdef, const Medium& med,
                                                 double energy, double v) {
            return p.DifferentialCrossSection(pdef, med, energy, v);
        })
        .method("get_kinematic_limits", [](const crosssection::Parametrization<Medium>& p,
                                           const ParticleDef& pdef, const Medium& med, double energy) {
            return p.GetKinematicLimits(pdef, med, energy);
        })
        .method("get_lower_energy_lim_param", [](const crosssection::Parametrization<Medium>& p,
                                                  const ParticleDef& pdef) {
            return p.GetLowerEnergyLim(pdef);
        })
        .method("get_hash", [](const crosssection::Parametrization<Medium>& p) {
            return static_cast<int64_t>(p.GetHash());
        });

    // ParametrizationDirect base
    mod.add_type<crosssection::ParametrizationDirect>("ParametrizationDirect")
        .method("get_interaction_type", [](const crosssection::ParametrizationDirect& p) {
            return static_cast<int>(p.GetInteractionType());
        });

    // ShadowEffect
    mod.add_type<crosssection::ShadowEffect>("ShadowEffect")
        .method("calculate_shadow_effect", [](crosssection::ShadowEffect& s,
                                              const Component& c, double x, double nu) {
            return s.CalculateShadowEffect(c, x, nu);
        });

    mod.add_type<crosssection::ShadowDuttaRenoSarcevicSeckel>("ShadowDuttaRenoSarcevicSeckel",
        jlcxx::julia_base_type<crosssection::ShadowEffect>())
        .constructor<>();

    mod.add_type<crosssection::ShadowButkevichMikheyev>("ShadowButkevichMikheyev",
        jlcxx::julia_base_type<crosssection::ShadowEffect>())
        .constructor<>();

    // --- Bremsstrahlung hierarchy ---
    mod.add_type<crosssection::Bremsstrahlung>("Bremsstrahlung",
        jlcxx::julia_base_type<crosssection::Parametrization<Component>>());

    mod.add_type<crosssection::BremsKelnerKokoulinPetrukhin>("BremsKelnerKokoulinPetrukhin",
        jlcxx::julia_base_type<crosssection::Bremsstrahlung>())
        .constructor<bool>();
    mod.add_type<crosssection::BremsPetrukhinShestakov>("BremsPetrukhinShestakov",
        jlcxx::julia_base_type<crosssection::Bremsstrahlung>())
        .constructor<bool>();
    mod.add_type<crosssection::BremsCompleteScreening>("BremsCompleteScreening",
        jlcxx::julia_base_type<crosssection::Bremsstrahlung>())
        .constructor<bool>();
    mod.add_type<crosssection::BremsAndreevBezrukovBugaev>("BremsAndreevBezrukovBugaev",
        jlcxx::julia_base_type<crosssection::Bremsstrahlung>())
        .constructor<bool>();
    mod.add_type<crosssection::BremsSandrockSoedingreksoRhode>("BremsSandrockSoedingreksoRhode",
        jlcxx::julia_base_type<crosssection::Bremsstrahlung>())
        .constructor<bool>();
    mod.add_type<crosssection::BremsElectronScreening>("BremsElectronScreening",
        jlcxx::julia_base_type<crosssection::Bremsstrahlung>())
        .constructor<bool>();

    // --- EpairProduction hierarchy ---
    mod.add_type<crosssection::EpairProduction>("EpairProduction",
        jlcxx::julia_base_type<crosssection::Parametrization<Component>>());
    mod.add_type<crosssection::EpairProductionRhoIntegral>("EpairProductionRhoIntegral",
        jlcxx::julia_base_type<crosssection::EpairProduction>());

    mod.add_type<crosssection::EpairKelnerKokoulinPetrukhin>("EpairKelnerKokoulinPetrukhin",
        jlcxx::julia_base_type<crosssection::EpairProductionRhoIntegral>())
        .constructor<bool>();
    mod.add_type<crosssection::EpairSandrockSoedingreksoRhode>("EpairSandrockSoedingreksoRhode",
        jlcxx::julia_base_type<crosssection::EpairProductionRhoIntegral>())
        .constructor<bool>();
    mod.add_type<crosssection::EpairForElectronPositron>("EpairForElectronPositron",
        jlcxx::julia_base_type<crosssection::EpairProductionRhoIntegral>())
        .constructor<bool>();

    // --- Photonuclear hierarchy ---
    mod.add_type<crosssection::Photonuclear>("Photonuclear",
        jlcxx::julia_base_type<crosssection::Parametrization<Component>>());

    // PhotoRealPhotonAssumption
    mod.add_type<crosssection::PhotoRealPhotonAssumption>("PhotoRealPhotonAssumption",
        jlcxx::julia_base_type<crosssection::Photonuclear>());

    mod.add_type<crosssection::PhotoZeus>("PhotoZeus",
        jlcxx::julia_base_type<crosssection::PhotoRealPhotonAssumption>())
        .constructor<bool>();
    mod.add_type<crosssection::PhotoBezrukovBugaev>("PhotoBezrukovBugaev",
        jlcxx::julia_base_type<crosssection::PhotoRealPhotonAssumption>())
        .constructor<bool>();
    mod.add_type<crosssection::PhotoKokoulin>("PhotoKokoulin",
        jlcxx::julia_base_type<crosssection::PhotoRealPhotonAssumption>())
        .constructor<bool>();
    mod.add_type<crosssection::PhotoRhode>("PhotoRhode",
        jlcxx::julia_base_type<crosssection::PhotoRealPhotonAssumption>())
        .constructor<bool>();

    // PhotoQ2Integral
    mod.add_type<crosssection::PhotoQ2Integral>("PhotoQ2Integral",
        jlcxx::julia_base_type<crosssection::Photonuclear>());

    mod.add_type<crosssection::PhotoAbramowiczLevinLevyMaor91>("PhotoAbramowiczLevinLevyMaor91",
        jlcxx::julia_base_type<crosssection::PhotoQ2Integral>());
    mod.add_type<crosssection::PhotoAbramowiczLevinLevyMaor97>("PhotoAbramowiczLevinLevyMaor97",
        jlcxx::julia_base_type<crosssection::PhotoQ2Integral>());
    mod.add_type<crosssection::PhotoButkevichMikheyev>("PhotoButkevichMikheyev_",
        jlcxx::julia_base_type<crosssection::PhotoQ2Integral>());
    mod.add_type<crosssection::PhotoRenoSarcevicSu>("PhotoRenoSarcevicSu",
        jlcxx::julia_base_type<crosssection::PhotoQ2Integral>());
    mod.add_type<crosssection::PhotoAbtFT>("PhotoAbtFT",
        jlcxx::julia_base_type<crosssection::PhotoQ2Integral>());
    mod.add_type<crosssection::PhotoBlockDurandHa>("PhotoBlockDurandHa",
        jlcxx::julia_base_type<crosssection::PhotoQ2Integral>());

    // Helper to create shared_ptr<ShadowEffect> from a concrete shadow object
    auto make_shadow_ptr = [](const crosssection::ShadowDuttaRenoSarcevicSeckel& s) {
        return std::make_shared<crosssection::ShadowDuttaRenoSarcevicSeckel>(s);
    };
    auto make_shadow_ptr_bm = [](const crosssection::ShadowButkevichMikheyev& s) {
        return std::make_shared<crosssection::ShadowButkevichMikheyev>(s);
    };

    // Factory functions for PhotoQ2 parametrizations with DuttaRenoSarcevicSeckel shadow
    mod.method("create_photo_allm91_drss", [](const crosssection::ShadowDuttaRenoSarcevicSeckel& s) {
        return crosssection::PhotoAbramowiczLevinLevyMaor91(std::make_shared<crosssection::ShadowDuttaRenoSarcevicSeckel>(s));
    });
    mod.method("create_photo_allm91_bm", [](const crosssection::ShadowButkevichMikheyev& s) {
        return crosssection::PhotoAbramowiczLevinLevyMaor91(std::make_shared<crosssection::ShadowButkevichMikheyev>(s));
    });
    mod.method("create_photo_allm97_drss", [](const crosssection::ShadowDuttaRenoSarcevicSeckel& s) {
        return crosssection::PhotoAbramowiczLevinLevyMaor97(std::make_shared<crosssection::ShadowDuttaRenoSarcevicSeckel>(s));
    });
    mod.method("create_photo_allm97_bm", [](const crosssection::ShadowButkevichMikheyev& s) {
        return crosssection::PhotoAbramowiczLevinLevyMaor97(std::make_shared<crosssection::ShadowButkevichMikheyev>(s));
    });
    mod.method("create_photo_butkevich_drss", [](const crosssection::ShadowDuttaRenoSarcevicSeckel& s) {
        return crosssection::PhotoButkevichMikheyev(std::make_shared<crosssection::ShadowDuttaRenoSarcevicSeckel>(s));
    });
    mod.method("create_photo_butkevich_bm", [](const crosssection::ShadowButkevichMikheyev& s) {
        return crosssection::PhotoButkevichMikheyev(std::make_shared<crosssection::ShadowButkevichMikheyev>(s));
    });
    mod.method("create_photo_reno_drss", [](const crosssection::ShadowDuttaRenoSarcevicSeckel& s) {
        return crosssection::PhotoRenoSarcevicSu(std::make_shared<crosssection::ShadowDuttaRenoSarcevicSeckel>(s));
    });
    mod.method("create_photo_reno_bm", [](const crosssection::ShadowButkevichMikheyev& s) {
        return crosssection::PhotoRenoSarcevicSu(std::make_shared<crosssection::ShadowButkevichMikheyev>(s));
    });
    mod.method("create_photo_abtft_drss", [](const crosssection::ShadowDuttaRenoSarcevicSeckel& s) {
        return crosssection::PhotoAbtFT(std::make_shared<crosssection::ShadowDuttaRenoSarcevicSeckel>(s));
    });
    mod.method("create_photo_abtft_bm", [](const crosssection::ShadowButkevichMikheyev& s) {
        return crosssection::PhotoAbtFT(std::make_shared<crosssection::ShadowButkevichMikheyev>(s));
    });
    mod.method("create_photo_blockdurandha_drss", [](const crosssection::ShadowDuttaRenoSarcevicSeckel& s) {
        return crosssection::PhotoBlockDurandHa(std::make_shared<crosssection::ShadowDuttaRenoSarcevicSeckel>(s));
    });
    mod.method("create_photo_blockdurandha_bm", [](const crosssection::ShadowButkevichMikheyev& s) {
        return crosssection::PhotoBlockDurandHa(std::make_shared<crosssection::ShadowButkevichMikheyev>(s));
    });

    // --- MupairProduction hierarchy ---
    mod.add_type<crosssection::MupairProduction>("MupairProduction",
        jlcxx::julia_base_type<crosssection::Parametrization<Component>>());
    mod.add_type<crosssection::MupairProductionRhoIntegral>("MupairProductionRhoIntegral",
        jlcxx::julia_base_type<crosssection::MupairProduction>());

    mod.add_type<crosssection::MupairKelnerKokoulinPetrukhin>("MupairKelnerKokoulinPetrukhin",
        jlcxx::julia_base_type<crosssection::MupairProductionRhoIntegral>())
        .constructor<>();

    // --- WeakInteraction ---
    mod.add_type<crosssection::WeakInteraction>("WeakInteraction",
        jlcxx::julia_base_type<crosssection::Parametrization<Component>>());

    mod.add_type<crosssection::WeakCooperSarkarMertsch>("WeakCooperSarkarMertsch",
        jlcxx::julia_base_type<crosssection::WeakInteraction>())
        .constructor<>();

    // --- Compton ---
    mod.add_type<crosssection::Compton>("Compton",
        jlcxx::julia_base_type<crosssection::Parametrization<Component>>());

    mod.add_type<crosssection::ComptonKleinNishina>("ComptonKleinNishina",
        jlcxx::julia_base_type<crosssection::Compton>())
        .constructor<>();

    // --- PhotoPairProduction ---
    mod.add_type<crosssection::PhotoPairProduction>("PhotoPairProduction",
        jlcxx::julia_base_type<crosssection::Parametrization<Component>>());

    mod.add_type<crosssection::PhotoPairTsai>("PhotoPairTsai",
        jlcxx::julia_base_type<crosssection::PhotoPairProduction>())
        .constructor<bool>();
    mod.add_type<crosssection::PhotoPairKochMotz>("PhotoPairKochMotz",
        jlcxx::julia_base_type<crosssection::PhotoPairProduction>())
        .constructor<bool>();

    // --- PhotoMuPairProduction ---
    mod.add_type<crosssection::PhotoMuPairProduction>("PhotoMuPairProduction",
        jlcxx::julia_base_type<crosssection::Parametrization<Component>>());

    mod.add_type<crosssection::PhotoMuPairBurkhardtKelnerKokoulin>("PhotoMuPairBurkhardtKelnerKokoulin",
        jlcxx::julia_base_type<crosssection::PhotoMuPairProduction>())
        .constructor<>();

    // --- Ionization ---
    mod.add_type<crosssection::Ionization>("Ionization",
        jlcxx::julia_base_type<crosssection::Parametrization<Medium>>());

    mod.add_type<crosssection::IonizBetheBlochRossi>("IonizBetheBlochRossi",
        jlcxx::julia_base_type<crosssection::Ionization>())
        .constructor<const EnergyCutSettings&>();
    mod.add_type<crosssection::IonizBergerSeltzerBhabha>("IonizBergerSeltzerBhabha",
        jlcxx::julia_base_type<crosssection::Ionization>())
        .constructor<const EnergyCutSettings&>();
    mod.add_type<crosssection::IonizBergerSeltzerMoller>("IonizBergerSeltzerMoller",
        jlcxx::julia_base_type<crosssection::Ionization>())
        .constructor<const EnergyCutSettings&>();

    // --- Annihilation ---
    mod.add_type<crosssection::Annihilation>("Annihilation",
        jlcxx::julia_base_type<crosssection::ParametrizationDirect>());

    mod.add_type<crosssection::AnnihilationHeitler>("AnnihilationHeitler",
        jlcxx::julia_base_type<crosssection::Annihilation>())
        .constructor<>();

    // --- Photoproduction ---
    mod.add_type<crosssection::Photoproduction>("Photoproduction",
        jlcxx::julia_base_type<crosssection::ParametrizationDirect>());

    mod.add_type<crosssection::PhotoproductionZeus>("PhotoproductionZeus",
        jlcxx::julia_base_type<crosssection::Photoproduction>())
        .constructor<>();
    mod.add_type<crosssection::PhotoproductionBezrukovBugaev>("PhotoproductionBezrukovBugaev",
        jlcxx::julia_base_type<crosssection::Photoproduction>())
        .constructor<>();
    mod.add_type<crosssection::PhotoproductionCaldwell>("PhotoproductionCaldwell",
        jlcxx::julia_base_type<crosssection::Photoproduction>())
        .constructor<>();
    mod.add_type<crosssection::PhotoproductionKokoulin>("PhotoproductionKokoulin",
        jlcxx::julia_base_type<crosssection::Photoproduction>())
        .constructor<>();
    mod.add_type<crosssection::PhotoproductionRhode>("PhotoproductionRhode",
        jlcxx::julia_base_type<crosssection::Photoproduction>())
        .constructor<>();
    mod.add_type<crosssection::PhotoproductionHeck>("PhotoproductionHeck",
        jlcxx::julia_base_type<crosssection::Photoproduction>())
        .constructor<>();
    mod.add_type<crosssection::PhotoproductionHeckC7Shadowing>("PhotoproductionHeckC7Shadowing",
        jlcxx::julia_base_type<crosssection::Photoproduction>())
        .constructor<>();

    // --- Photoeffect ---
    mod.add_type<crosssection::Photoeffect>("Photoeffect",
        jlcxx::julia_base_type<crosssection::ParametrizationDirect>());

    mod.add_type<crosssection::PhotoeffectSauter>("PhotoeffectSauter",
        jlcxx::julia_base_type<crosssection::Photoeffect>())
        .constructor<>();

    // --- LPM correction objects ---
    mod.add_type<crosssection::BremsLPM>("BremsLPM")
        .method("suppression_factor", [](const crosssection::BremsLPM& lpm,
                                         double energy, double v, const Component& comp, double density_correction) {
            return lpm.suppression_factor(energy, v, comp, density_correction);
        })
        .method("get_hash", [](const crosssection::BremsLPM& lpm) {
            return static_cast<int64_t>(lpm.GetHash());
        });
    // BremsLPM factory (requires ParticleDef, Medium, and a Bremsstrahlung parametrization)
    mod.method("create_brems_lpm", [](const ParticleDef& pdef, const Medium& med,
                                      const crosssection::Bremsstrahlung& brems) {
        return crosssection::BremsLPM(pdef, med, brems);
    });

    mod.add_type<crosssection::EpairLPM>("EpairLPM")
        .method("suppression_factor", [](const crosssection::EpairLPM& lpm,
                                         double E, double v, double r2, double beta, double xi, double density_correction) {
            return lpm.suppression_factor(E, v, r2, beta, xi, density_correction);
        })
        .method("get_hash", [](const crosssection::EpairLPM& lpm) {
            return static_cast<int64_t>(lpm.GetHash());
        });
    mod.method("create_epair_lpm", [](const ParticleDef& pdef, const Medium& med) {
        return crosssection::EpairLPM(pdef, med);
    });

    mod.add_type<crosssection::PhotoPairLPM>("PhotoPairLPM")
        .method("suppression_factor", [](const crosssection::PhotoPairLPM& lpm,
                                         double energy, double x, const Component& comp, double density_correction) {
            return lpm.suppression_factor(energy, x, comp, density_correction);
        })
        .method("get_hash", [](const crosssection::PhotoPairLPM& lpm) {
            return static_cast<int64_t>(lpm.GetHash());
        });
    mod.method("create_photopair_lpm", [](const ParticleDef& pdef, const Medium& med,
                                           const crosssection::PhotoPairProduction& pp) {
        return crosssection::PhotoPairLPM(pdef, med, pp);
    });

    // Per-particle standard cross-section factories
    mod.method("make_std_crosssection_muminus", [](const Medium& m, double ecut, double vcut, bool cont_rand, bool interpolate) {
        auto cuts = std::make_shared<const EnergyCutSettings>(ecut, vcut, cont_rand);
        auto cross = GetStdCrossSections(MuMinusDef(), m, cuts, interpolate);
        int handle = static_cast<int>(g_crosssection_sets.size());
        g_crosssection_sets.push_back(std::move(cross));
        return handle;
    });
    mod.method("make_std_crosssection_muplus", [](const Medium& m, double ecut, double vcut, bool cont_rand, bool interpolate) {
        auto cuts = std::make_shared<const EnergyCutSettings>(ecut, vcut, cont_rand);
        auto cross = GetStdCrossSections(MuPlusDef(), m, cuts, interpolate);
        int handle = static_cast<int>(g_crosssection_sets.size());
        g_crosssection_sets.push_back(std::move(cross));
        return handle;
    });
    mod.method("make_std_crosssection_eminus", [](const Medium& m, double ecut, double vcut, bool cont_rand, bool interpolate) {
        auto cuts = std::make_shared<const EnergyCutSettings>(ecut, vcut, cont_rand);
        auto cross = GetStdCrossSections(EMinusDef(), m, cuts, interpolate);
        int handle = static_cast<int>(g_crosssection_sets.size());
        g_crosssection_sets.push_back(std::move(cross));
        return handle;
    });
    mod.method("make_std_crosssection_eplus", [](const Medium& m, double ecut, double vcut, bool cont_rand, bool interpolate) {
        auto cuts = std::make_shared<const EnergyCutSettings>(ecut, vcut, cont_rand);
        auto cross = GetStdCrossSections(EPlusDef(), m, cuts, interpolate);
        int handle = static_cast<int>(g_crosssection_sets.size());
        g_crosssection_sets.push_back(std::move(cross));
        return handle;
    });
    mod.method("make_std_crosssection_tauminus", [](const Medium& m, double ecut, double vcut, bool cont_rand, bool interpolate) {
        auto cuts = std::make_shared<const EnergyCutSettings>(ecut, vcut, cont_rand);
        auto cross = GetStdCrossSections(TauMinusDef(), m, cuts, interpolate);
        int handle = static_cast<int>(g_crosssection_sets.size());
        g_crosssection_sets.push_back(std::move(cross));
        return handle;
    });
    mod.method("make_std_crosssection_tauplus", [](const Medium& m, double ecut, double vcut, bool cont_rand, bool interpolate) {
        auto cuts = std::make_shared<const EnergyCutSettings>(ecut, vcut, cont_rand);
        auto cross = GetStdCrossSections(TauPlusDef(), m, cuts, interpolate);
        int handle = static_cast<int>(g_crosssection_sets.size());
        g_crosssection_sets.push_back(std::move(cross));
        return handle;
    });
    mod.method("make_std_crosssection_gamma", [](const Medium& m, double ecut, double vcut, bool cont_rand, bool interpolate) {
        auto cuts = std::make_shared<const EnergyCutSettings>(ecut, vcut, cont_rand);
        auto cross = GetStdCrossSections(GammaDef(), m, cuts, interpolate);
        int handle = static_cast<int>(g_crosssection_sets.size());
        g_crosssection_sets.push_back(std::move(cross));
        return handle;
    });

    // ========== make_crosssection from individual parametrizations ==========
    // Macro for Parametrization<Component> subtypes (with cuts)
#define WRAP_MAKE_CS_COMP(CppType, JuliaName) \
    mod.method("make_crosssection_" JuliaName, [](crosssection::CppType& param, \
                const ParticleDef& pdef, const Medium& medium, \
                double ecut, double vcut, bool cont_rand, bool interpolate) { \
        auto cuts = std::make_shared<const EnergyCutSettings>(ecut, vcut, cont_rand); \
        auto cs = make_crosssection(param, pdef, medium, cuts, interpolate); \
        int handle = static_cast<int>(g_crosssection_sets.size()); \
        std::vector<std::shared_ptr<CrossSectionBase>> vec; \
        vec.push_back(std::move(cs)); \
        g_crosssection_sets.push_back(std::move(vec)); \
        return handle; \
    });

    // Macro for ParametrizationDirect subtypes (no cuts)
#define WRAP_MAKE_CS_DIRECT(CppType, JuliaName) \
    mod.method("make_crosssection_" JuliaName, [](crosssection::CppType& param, \
                const ParticleDef& pdef, const Medium& medium, bool interpolate) { \
        auto cs = make_crosssection(param, pdef, medium, nullptr, interpolate); \
        int handle = static_cast<int>(g_crosssection_sets.size()); \
        std::vector<std::shared_ptr<CrossSectionBase>> vec; \
        vec.push_back(std::move(cs)); \
        g_crosssection_sets.push_back(std::move(vec)); \
        return handle; \
    });

    // Macro for Parametrization<Medium> subtypes (with cuts)
#define WRAP_MAKE_CS_MED(CppType, JuliaName) \
    mod.method("make_crosssection_" JuliaName, [](crosssection::CppType& param, \
                const ParticleDef& pdef, const Medium& medium, \
                double ecut, double vcut, bool cont_rand, bool interpolate) { \
        auto cuts = std::make_shared<const EnergyCutSettings>(ecut, vcut, cont_rand); \
        auto cs = make_crosssection(param, pdef, medium, cuts, interpolate); \
        int handle = static_cast<int>(g_crosssection_sets.size()); \
        std::vector<std::shared_ptr<CrossSectionBase>> vec; \
        vec.push_back(std::move(cs)); \
        g_crosssection_sets.push_back(std::move(vec)); \
        return handle; \
    });

    // Bremsstrahlung
    WRAP_MAKE_CS_COMP(BremsKelnerKokoulinPetrukhin, "brems_kkp")
    WRAP_MAKE_CS_COMP(BremsPetrukhinShestakov, "brems_ps")
    WRAP_MAKE_CS_COMP(BremsCompleteScreening, "brems_cs")
    WRAP_MAKE_CS_COMP(BremsAndreevBezrukovBugaev, "brems_abb")
    WRAP_MAKE_CS_COMP(BremsSandrockSoedingreksoRhode, "brems_ssr")
    WRAP_MAKE_CS_COMP(BremsElectronScreening, "brems_es")

    // EpairProduction
    WRAP_MAKE_CS_COMP(EpairKelnerKokoulinPetrukhin, "epair_kkp")
    WRAP_MAKE_CS_COMP(EpairSandrockSoedingreksoRhode, "epair_ssr")
    WRAP_MAKE_CS_COMP(EpairForElectronPositron, "epair_fep")

    // Photonuclear (real photon)
    WRAP_MAKE_CS_COMP(PhotoZeus, "photo_zeus")
    WRAP_MAKE_CS_COMP(PhotoBezrukovBugaev, "photo_bb")
    WRAP_MAKE_CS_COMP(PhotoKokoulin, "photo_kokoulin")
    WRAP_MAKE_CS_COMP(PhotoRhode, "photo_rhode")

    // Photonuclear (Q2)
    WRAP_MAKE_CS_COMP(PhotoAbramowiczLevinLevyMaor91, "photo_allm91")
    WRAP_MAKE_CS_COMP(PhotoAbramowiczLevinLevyMaor97, "photo_allm97")
    WRAP_MAKE_CS_COMP(PhotoButkevichMikheyev, "photo_bm")
    WRAP_MAKE_CS_COMP(PhotoRenoSarcevicSu, "photo_rss")
    WRAP_MAKE_CS_COMP(PhotoAbtFT, "photo_abtft")
    WRAP_MAKE_CS_COMP(PhotoBlockDurandHa, "photo_bdh")

    // Mupair
    WRAP_MAKE_CS_COMP(MupairKelnerKokoulinPetrukhin, "mupair_kkp")

    // WeakInteraction
    WRAP_MAKE_CS_COMP(WeakCooperSarkarMertsch, "weak_csm")

    // Compton
    WRAP_MAKE_CS_COMP(ComptonKleinNishina, "compton_kn")

    // PhotoPairProduction
    WRAP_MAKE_CS_COMP(PhotoPairTsai, "photopair_tsai")
    WRAP_MAKE_CS_COMP(PhotoPairKochMotz, "photopair_km")

    // PhotoMuPairProduction
    WRAP_MAKE_CS_COMP(PhotoMuPairBurkhardtKelnerKokoulin, "photomupair_bkk")

    // Ionization (Parametrization<Medium>)
    WRAP_MAKE_CS_MED(IonizBetheBlochRossi, "ioniz_bbr")
    WRAP_MAKE_CS_MED(IonizBergerSeltzerBhabha, "ioniz_bsb")
    WRAP_MAKE_CS_MED(IonizBergerSeltzerMoller, "ioniz_bsm")

    // Annihilation (ParametrizationDirect)
    WRAP_MAKE_CS_DIRECT(AnnihilationHeitler, "annihilation_heitler")

    // Photoproduction (ParametrizationDirect)
    WRAP_MAKE_CS_DIRECT(PhotoproductionZeus, "photoproduction_zeus")
    WRAP_MAKE_CS_DIRECT(PhotoproductionBezrukovBugaev, "photoproduction_bb")
    WRAP_MAKE_CS_DIRECT(PhotoproductionCaldwell, "photoproduction_caldwell")
    WRAP_MAKE_CS_DIRECT(PhotoproductionKokoulin, "photoproduction_kokoulin")
    WRAP_MAKE_CS_DIRECT(PhotoproductionRhode, "photoproduction_rhode")
    WRAP_MAKE_CS_DIRECT(PhotoproductionHeck, "photoproduction_heck")
    WRAP_MAKE_CS_DIRECT(PhotoproductionHeckC7Shadowing, "photoproduction_heckc7")

    // Photoeffect (ParametrizationDirect)
    WRAP_MAKE_CS_DIRECT(PhotoeffectSauter, "photoeffect_sauter")

#undef WRAP_MAKE_CS_COMP
#undef WRAP_MAKE_CS_DIRECT
#undef WRAP_MAKE_CS_MED

    // ========== Phase 8: SecondariesCalculator ==========

    // Handle-based storage for SecondariesCalculator (not copyable due to unique_ptr members)
    static std::vector<std::unique_ptr<SecondariesCalculator>> g_sec_calcs;
    static std::vector<ParticleState> g_sec_calc_results;

    mod.method("create_secondaries_calculator", [](int cross_handle,
                                                    const ParticleDef& p,
                                                    const Medium& m) {
        auto& cross = g_crosssection_sets.at(cross_handle);
        std::vector<InteractionType> types;
        for (auto& cs : cross) {
            types.push_back(cs->GetInteractionType());
        }
        int handle = static_cast<int>(g_sec_calcs.size());
        g_sec_calcs.push_back(std::make_unique<SecondariesCalculator>(types, p, m));
        return handle;
    });

    mod.method("sec_calc_required_random_numbers", [](int handle, int type) {
        return static_cast<int>(g_sec_calcs.at(handle)->RequiredRandomNumbers(
            static_cast<InteractionType>(type)));
    });

    mod.method("sec_calc_calculate", [](int handle,
                                        const StochasticLoss& loss,
                                        const Component& comp,
                                        jlcxx::ArrayRef<double> rnd_arr) {
        std::vector<double> rnd(rnd_arr.begin(), rnd_arr.end());
        g_sec_calc_results = g_sec_calcs.at(handle)->CalculateSecondaries(loss, comp, rnd);
        return static_cast<int>(g_sec_calc_results.size());
    });

    mod.method("sec_calc_result_at", [](int i) -> ParticleState {
        return g_sec_calc_results.at(i);
    });

    mod.method("free_secondaries_calculator", [](int handle) {
        if (handle >= 0 && handle < static_cast<int>(g_sec_calcs.size())) {
            g_sec_calcs[handle].reset();
        }
    });

    // ========== Phase 9: Additional CrossSection & Scattering methods ==========

    // CrossSectionBase additional methods
    mod.method("calculate_cumulative_crosssection", [](CrossSectionBase& cs,
                                                        double energy, int64_t component_hash, double v) {
        return cs.CalculateCumulativeCrosssection(energy, static_cast<size_t>(component_hash), v);
    });

    mod.method("calculate_dNdx_per_target", [](CrossSectionBase& cs,
                                                double energy, int64_t component_hash) {
        return cs.CalculatedNdx(energy, static_cast<size_t>(component_hash));
    });

    mod.method("get_crosssection_hash", [](const CrossSectionBase& cs) {
        return static_cast<int64_t>(cs.GetHash());
    });

    // Scattering: multiple scattering
    mod.method("scattering_multiple_scatter", [](Scattering& scat,
                                                  double grammage, double ei, double ef,
                                                  double r1, double r2, double r3, double r4) {
        std::array<double, 4> rnd = {r1, r2, r3, r4};
        return scat.CalculateMultipleScattering(grammage, ei, ef, rnd);
    });

    // Scattering: stochastic deflection (initial_energy, final_energy, rnd_vector, component_hash)
    mod.method("scattering_stochastic_deflection", [](Scattering& scat,
                                                       int interaction_type,
                                                       double initial_energy, double final_energy,
                                                       jlcxx::ArrayRef<double> rnd_arr,
                                                       int64_t component) {
        std::vector<double> rnd(rnd_arr.begin(), rnd_arr.end());
        return scat.CalculateStochasticDeflection(
            static_cast<InteractionType>(interaction_type),
            initial_energy, final_energy, rnd, static_cast<size_t>(component));
    });

    // Scattering: random number counts
    mod.method("scattering_ms_random_numbers", [](const Scattering& scat) {
        return static_cast<int>(scat.MultipleScatteringRandomNumbers());
    });

    mod.method("scattering_sd_random_numbers", [](const Scattering& scat, int interaction_type) {
        return static_cast<int>(scat.StochasticDeflectionRandomNumbers(
            static_cast<InteractionType>(interaction_type)));
    });

    // ========== Phase 10: Math/Interpolation types ==========

    // Polynom
    mod.add_type<Polynom>("Polynom")
        .constructor<std::vector<double>>()
        .method("evaluate", &Polynom::evaluate)
        .method("get_coefficient", &Polynom::GetCoefficient)
        .method("derive", &Polynom::GetDerivative)
        .method("antiderivative", &Polynom::GetAntiderivative);

    // Spline base
    mod.add_type<Spline>("Spline")
        .method("evaluate", &Spline::evaluate)
        .method("derive", &Spline::Derivative)
        .method("antiderivative", &Spline::Antiderivative);

    // Linear_Spline
    mod.add_type<Linear_Spline>("LinearSpline", jlcxx::julia_base_type<Spline>())
        .constructor<std::vector<double>, std::vector<double>>();

    // Cubic_Spline
    mod.add_type<Cubic_Spline>("CubicSpline", jlcxx::julia_base_type<Spline>())
        .constructor<std::vector<double>, std::vector<double>>();

    // ========== Phase 11: Additional Density types ==========

    mod.add_type<Density_polynomial>("DensityPolynomial", jlcxx::julia_base_type<Density_distr>())
        .constructor<const Axis&, const Polynom&, double>();

    mod.add_type<Density_splines>("DensitySplines", jlcxx::julia_base_type<Density_distr>())
        .constructor<const Axis&, const Spline&, double>();

    // ========== Phase 12: Lookup & utility functions ==========

    mod.method("get_particle_def_for_type", [](int type) {
        return ParticleDef::GetParticleDefForType(type);
    });

    // ========== InterpolationSettings ==========

    mod.method("get_tables_path", []() { return InterpolationSettings::TABLES_PATH; });
    mod.method("set_tables_path", [](const std::string& path) { InterpolationSettings::TABLES_PATH = path; });
    mod.method("get_upper_energy_lim", []() { return InterpolationSettings::UPPER_ENERGY_LIM; });
    mod.method("set_upper_energy_lim", [](double val) { InterpolationSettings::UPPER_ENERGY_LIM = val; });
    mod.method("get_nodes_dedx", []() { return static_cast<int>(InterpolationSettings::NODES_DEDX); });
    mod.method("set_nodes_dedx", [](int val) { InterpolationSettings::NODES_DEDX = static_cast<unsigned int>(val); });
    mod.method("get_nodes_de2dx", []() { return static_cast<int>(InterpolationSettings::NODES_DE2DX); });
    mod.method("set_nodes_de2dx", [](int val) { InterpolationSettings::NODES_DE2DX = static_cast<unsigned int>(val); });
    mod.method("get_nodes_dndx_e", []() { return static_cast<int>(InterpolationSettings::NODES_DNDX_E); });
    mod.method("set_nodes_dndx_e", [](int val) { InterpolationSettings::NODES_DNDX_E = static_cast<unsigned int>(val); });
    mod.method("get_nodes_dndx_v", []() { return static_cast<int>(InterpolationSettings::NODES_DNDX_V); });
    mod.method("set_nodes_dndx_v", [](int val) { InterpolationSettings::NODES_DNDX_V = static_cast<unsigned int>(val); });
    mod.method("get_nodes_utility", []() { return static_cast<int>(InterpolationSettings::NODES_UTILITY); });
    mod.method("set_nodes_utility", [](int val) { InterpolationSettings::NODES_UTILITY = static_cast<unsigned int>(val); });
    mod.method("get_nodes_rate_interpolant", []() { return static_cast<int>(InterpolationSettings::NODES_RATE_INTERPOLANT); });
    mod.method("set_nodes_rate_interpolant", [](int val) { InterpolationSettings::NODES_RATE_INTERPOLANT = static_cast<unsigned int>(val); });

    // ========== PropagationSettings ==========

    mod.method("get_max_steps", []() { return static_cast<int>(PropagationSettings::ADVANCE_PARTICLE_MAX_STEPS); });
    mod.method("set_max_steps", [](int val) { PropagationSettings::ADVANCE_PARTICLE_MAX_STEPS = static_cast<unsigned int>(val); });

    // ========== Logging ==========

    mod.method("set_loglevel", [](int level) {
        spdlog::level::level_enum lvl;
        switch (level) {
            case 0: lvl = spdlog::level::trace; break;
            case 1: lvl = spdlog::level::debug; break;
            case 2: lvl = spdlog::level::info; break;
            case 3: lvl = spdlog::level::warn; break;
            case 4: lvl = spdlog::level::err; break;
            case 5: lvl = spdlog::level::critical; break;
            case 6: lvl = spdlog::level::off; break;
            default: lvl = spdlog::level::warn; break;
        }
        Logging::SetGlobalLoglevel(lvl);
    });

    // ========== Random Number Generator ==========

    mod.method("set_random_seed", [](int seed) {
        RandomGenerator::Get().SetSeed(seed);
    });

    mod.method("random_double", []() {
        return RandomGenerator::Get().RandomDouble();
    });

    // ========== Version ==========

    mod.method("get_proposal_version", &getPROPOSALVersion);

    // ========== Constants ==========

    mod.set_const("SPEED_OF_LIGHT", SPEED);
    mod.set_const("ELECTRON_MASS", ME);
    mod.set_const("MUON_MASS", MMU);
    mod.set_const("TAU_MASS", MTAU);
    mod.set_const("PROTON_MASS", MP);

    // ========== Particle Type Constants ==========
    mod.set_const("PARTICLE_TYPE_NONE", static_cast<int>(ParticleType::None));
    mod.set_const("PARTICLE_TYPE_EMINUS", static_cast<int>(ParticleType::EMinus));
    mod.set_const("PARTICLE_TYPE_EPLUS", static_cast<int>(ParticleType::EPlus));
    mod.set_const("PARTICLE_TYPE_MUMINUS", static_cast<int>(ParticleType::MuMinus));
    mod.set_const("PARTICLE_TYPE_MUPLUS", static_cast<int>(ParticleType::MuPlus));
    mod.set_const("PARTICLE_TYPE_TAUMINUS", static_cast<int>(ParticleType::TauMinus));
    mod.set_const("PARTICLE_TYPE_TAUPLUS", static_cast<int>(ParticleType::TauPlus));
    mod.set_const("PARTICLE_TYPE_GAMMA", static_cast<int>(ParticleType::Gamma));
    mod.set_const("PARTICLE_TYPE_PI0", static_cast<int>(ParticleType::Pi0));
    mod.set_const("PARTICLE_TYPE_PIPLUS", static_cast<int>(ParticleType::PiPlus));
    mod.set_const("PARTICLE_TYPE_PIMINUS", static_cast<int>(ParticleType::PiMinus));
    mod.set_const("PARTICLE_TYPE_K0", static_cast<int>(ParticleType::K0));
    mod.set_const("PARTICLE_TYPE_KPLUS", static_cast<int>(ParticleType::KPlus));
    mod.set_const("PARTICLE_TYPE_KMINUS", static_cast<int>(ParticleType::KMinus));
    mod.set_const("PARTICLE_TYPE_NUE", static_cast<int>(ParticleType::NuE));
    mod.set_const("PARTICLE_TYPE_NUEBAR", static_cast<int>(ParticleType::NuEBar));
    mod.set_const("PARTICLE_TYPE_NUMU", static_cast<int>(ParticleType::NuMu));
    mod.set_const("PARTICLE_TYPE_NUMUBAR", static_cast<int>(ParticleType::NuMuBar));
    mod.set_const("PARTICLE_TYPE_NUTAU", static_cast<int>(ParticleType::NuTau));
    mod.set_const("PARTICLE_TYPE_NUTAUBAR", static_cast<int>(ParticleType::NuTauBar));
    mod.set_const("PARTICLE_TYPE_STAUMINUS", static_cast<int>(ParticleType::STauMinus));
    mod.set_const("PARTICLE_TYPE_STAUPLUS", static_cast<int>(ParticleType::STauPlus));
    mod.set_const("PARTICLE_TYPE_MONOPOLE", static_cast<int>(ParticleType::Monopole));
    mod.set_const("PARTICLE_TYPE_SMPPLUS", static_cast<int>(ParticleType::SMPPlus));
    mod.set_const("PARTICLE_TYPE_SMPMINUS", static_cast<int>(ParticleType::SMPMinus));
    mod.set_const("PARTICLE_TYPE_HADRON", static_cast<int>(ParticleType::Hadron));

    // ========== InteractionType Constants ==========
    mod.set_const("INTERACTION_TYPE_UNDEFINED", static_cast<int>(InteractionType::Undefined));
    mod.set_const("INTERACTION_TYPE_PARTICLE", static_cast<int>(InteractionType::Particle));
    mod.set_const("INTERACTION_TYPE_BREMS", static_cast<int>(InteractionType::Brems));
    mod.set_const("INTERACTION_TYPE_IONIZ", static_cast<int>(InteractionType::Ioniz));
    mod.set_const("INTERACTION_TYPE_EPAIR", static_cast<int>(InteractionType::Epair));
    mod.set_const("INTERACTION_TYPE_PHOTONUCLEAR", static_cast<int>(InteractionType::Photonuclear));
    mod.set_const("INTERACTION_TYPE_MUPAIR", static_cast<int>(InteractionType::MuPair));
    mod.set_const("INTERACTION_TYPE_HADRONS", static_cast<int>(InteractionType::Hadrons));
    mod.set_const("INTERACTION_TYPE_CONTINUOUS_ENERGY_LOSS", static_cast<int>(InteractionType::ContinuousEnergyLoss));
    mod.set_const("INTERACTION_TYPE_WEAKINT", static_cast<int>(InteractionType::WeakInt));
    mod.set_const("INTERACTION_TYPE_COMPTON", static_cast<int>(InteractionType::Compton));
    mod.set_const("INTERACTION_TYPE_DECAY", static_cast<int>(InteractionType::Decay));
    mod.set_const("INTERACTION_TYPE_ANNIHILATION", static_cast<int>(InteractionType::Annihilation));
    mod.set_const("INTERACTION_TYPE_PHOTOPAIR", static_cast<int>(InteractionType::Photopair));
    mod.set_const("INTERACTION_TYPE_PHOTOPRODUCTION", static_cast<int>(InteractionType::Photoproduction));
    mod.set_const("INTERACTION_TYPE_PHOTOMUPAIR", static_cast<int>(InteractionType::PhotoMuPair));
    mod.set_const("INTERACTION_TYPE_PHOTOEFFECT", static_cast<int>(InteractionType::Photoeffect));

    // ========== Log Level Constants ==========
    mod.set_const("LOG_TRACE", 0);
    mod.set_const("LOG_DEBUG", 1);
    mod.set_const("LOG_INFO", 2);
    mod.set_const("LOG_WARN", 3);
    mod.set_const("LOG_ERROR", 4);
    mod.set_const("LOG_CRITICAL", 5);
    mod.set_const("LOG_OFF", 6);
}
