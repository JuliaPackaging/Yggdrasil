#include "jlcxx/jlcxx.hpp"
#include <scopehal.h>

jlcxx::Array<float> AnalogWaveformData(WaveformBase* wf) {
  auto awf = dynamic_cast<AnalogWaveform*>(wf);
  std::cout << "pointer " << awf << " base ptr " << wf;
  size_t zero = 0;
  if(awf == nullptr) return jlcxx::Array<float>(zero);
  auto samples = awf->m_samples;
  // jlcxx::ArrayRef<float, 1> ja((float*)&samples[0], samples.size());
  // for (int i=0; i<samples.size(); i++) {
  //     jl_arrayset(ja.wrapped(), jl_box_float32(samples[i]), i);
  // }
  jlcxx::Array<float>ja(zero);
  for(float i : samples) {
    ja.push_back(i);
  }
  return ja;
}

FunctionGenerator* GetFunctionGenerator(Instrument* inst) {
  unsigned int t = inst->GetInstrumentTypes();
  if ((t & Instrument::INST_FUNCTION) == 0) return nullptr;
  return dynamic_cast<FunctionGenerator*>(inst);
}

namespace jlcxx
{
  // Needed for upcasting
  template<> struct SuperType<Oscilloscope> { typedef Instrument type; };
  template<> struct SuperType<Trigger> { typedef FlowGraphNode type; };
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    mod.add_type<FlowGraphNode>("FlowGraphNode");
    mod.add_type<Trigger>("Trigger", jlcxx::julia_base_type<FlowGraphNode>());
    mod.add_type<WaveformBase>("WaveformBase");
    mod.add_type<Unit>("Unit");

    mod.add_type<SCPITransport>("SCPITransport")
        .method("GetConnectionString", &SCPITransport::GetConnectionString)
        .method("GetName", &SCPITransport::GetName)
        .method("SendCommandQueued", &SCPITransport::SendCommandQueued)
        .method("SendCommandQueuedWithReply", &SCPITransport::SendCommandQueuedWithReply)
        .method("SendCommandImmediate", &SCPITransport::SendCommandImmediate)
        .method("SendCommandImmediateWithReply", &SCPITransport::SendCommandImmediateWithReply)
        .method("SendCommandImmediateWithRawBlockReply", &SCPITransport::SendCommandImmediateWithRawBlockReply)
        .method("FlushCommandQueue", &SCPITransport::FlushCommandQueue)
        // .method("GetMutex", &SCPITransport::GetMutex)
        .method("FlushRXBuffer", &SCPITransport::FlushRXBuffer)
        .method("SendCommand", &SCPITransport::SendCommand)
        .method("ReadReply", &SCPITransport::ReadReply)
        .method("ReadRawData", &SCPITransport::ReadRawData)
        .method("SendRawData", &SCPITransport::SendRawData)
        .method("IsCommandBatchingSupported", &SCPITransport::IsCommandBatchingSupported)
        .method("IsConnected", &SCPITransport::IsConnected)
        // .method("DoAddTransportClass", &SCPITransport::DoAddTransportClass)
        .method("EnumTransports", &SCPITransport::EnumTransports)
        .method("CreateTransport", &SCPITransport::CreateTransport);


  
    mod.add_bits<OscilloscopeChannel::ChannelType>("ChannelType", jlcxx::julia_type("CppEnum"));
    mod.set_const("CHANNEL_TYPE_ANALOG", OscilloscopeChannel::CHANNEL_TYPE_ANALOG);
    mod.set_const("CHANNEL_TYPE_DIGITAL", OscilloscopeChannel::CHANNEL_TYPE_DIGITAL);
    mod.set_const("CHANNEL_TYPE_EYE", OscilloscopeChannel::CHANNEL_TYPE_EYE);
    mod.set_const("CHANNEL_TYPE_SPECTROGRAM", OscilloscopeChannel::CHANNEL_TYPE_SPECTROGRAM);
    mod.set_const("CHANNEL_TYPE_TRIGGER", OscilloscopeChannel::CHANNEL_TYPE_TRIGGER);
    mod.set_const("CHANNEL_TYPE_COMPLEX", OscilloscopeChannel::CHANNEL_TYPE_COMPLEX);

    mod.add_bits<OscilloscopeChannel::CouplingType>("CouplingType", jlcxx::julia_type("CppEnum"));
    mod.set_const("COUPLE_DC_1M", OscilloscopeChannel::COUPLE_DC_1M);
    mod.set_const("COUPLE_AC_1M", OscilloscopeChannel::COUPLE_AC_1M);
    mod.set_const("COUPLE_DC_50", OscilloscopeChannel::COUPLE_DC_50);
    mod.set_const("COUPLE_AC_50", OscilloscopeChannel::COUPLE_AC_50);
    mod.set_const("COUPLE_GND", OscilloscopeChannel::COUPLE_GND);
    mod.set_const("COUPLE_SYNTHETIC", OscilloscopeChannel::COUPLE_SYNTHETIC);

    mod.add_type<OscilloscopeChannel>("OscilloscopeChannel")
        .method("GetType", &OscilloscopeChannel::GetType)
        .method("GetHwname", &OscilloscopeChannel::GetHwname)
        .method("GetStreamCount", &OscilloscopeChannel::GetStreamCount)
        .method("GetStreamName", &OscilloscopeChannel::GetStreamName)
        .method("GetData", &OscilloscopeChannel::GetData)
        .method("Detach", &OscilloscopeChannel::Detach)
        .method("SetData", &OscilloscopeChannel::SetData)
        .method("GetWidth", &OscilloscopeChannel::GetWidth)
        // .method("GetScope", &OscilloscopeChannel::GetScope)
        .method("GetIndex", &OscilloscopeChannel::GetIndex)
        .method("GetRefCount", &OscilloscopeChannel::GetRefCount)
        .method("SetDisplayName", &OscilloscopeChannel::SetDisplayName)
        .method("GetDisplayName", &OscilloscopeChannel::GetDisplayName)
        .method("IsEnabled", &OscilloscopeChannel::IsEnabled)
        .method("Enable", &OscilloscopeChannel::Enable)
        .method("Disable", &OscilloscopeChannel::Disable)
        .method("AddRef", &OscilloscopeChannel::AddRef)
        .method("Release", &OscilloscopeChannel::Release)
        .method("GetCoupling", &OscilloscopeChannel::GetCoupling)
        .method("SetCoupling", &OscilloscopeChannel::SetCoupling)
        // .method("GetAvailableCouplings", &OscilloscopeChannel::GetAvailableCouplings)
        .method("GetAttenuation", &OscilloscopeChannel::GetAttenuation)
        .method("SetAttenuation", &OscilloscopeChannel::SetAttenuation)
        .method("GetBandwidthLimit", &OscilloscopeChannel::GetBandwidthLimit)
        .method("SetBandwidthLimit", &OscilloscopeChannel::SetBandwidthLimit)
        .method("SetDeskew", &OscilloscopeChannel::SetDeskew)
        .method("GetDeskew", &OscilloscopeChannel::GetDeskew)
        .method("IsPhysicalChannel", &OscilloscopeChannel::IsPhysicalChannel)
        .method("GetVoltageRange", &OscilloscopeChannel::GetVoltageRange)
        .method("SetVoltageRange", &OscilloscopeChannel::SetVoltageRange)
        .method("GetOffset", &OscilloscopeChannel::GetOffset)
        .method("SetOffset", &OscilloscopeChannel::SetOffset)
        .method("GetXAxisUnits", &OscilloscopeChannel::GetXAxisUnits)
        .method("GetYAxisUnits", &OscilloscopeChannel::GetYAxisUnits)
        .method("SetDigitalHysteresis", &OscilloscopeChannel::SetDigitalHysteresis)
        .method("SetDigitalThreshold", &OscilloscopeChannel::SetDigitalThreshold)
        .method("SetCenterFrequency", &OscilloscopeChannel::SetCenterFrequency)
        .method("CanAutoZero", &OscilloscopeChannel::CanAutoZero)
        .method("AutoZero", &OscilloscopeChannel::AutoZero)
        .method("GetProbeName", &OscilloscopeChannel::GetProbeName)
        .method("CanInvert", &OscilloscopeChannel::CanInvert)
        .method("Invert", &OscilloscopeChannel::Invert)
        .method("IsInverted", &OscilloscopeChannel::IsInverted)
        .method("SetInputMux", &OscilloscopeChannel::SetInputMux)
        .method("SetDefaultDisplayName", &OscilloscopeChannel::SetDefaultDisplayName);

    mod.add_type<Instrument>("Instrument")
        .method("GetInstrumentTypes", &Instrument::GetInstrumentTypes)
        .method("GetName", &Instrument::GetName)
        .method("GetVendor", &Instrument::GetVendor)
        .method("GetSerial", &Instrument::GetSerial);

    mod.add_bits<Oscilloscope::TriggerMode>("TriggerMode", jlcxx::julia_type("CppEnum"));
    mod.set_const("TRIGGER_MODE_RUN", Oscilloscope::TRIGGER_MODE_RUN);
    mod.set_const("TRIGGER_MODE_STOP", Oscilloscope::TRIGGER_MODE_STOP);
    mod.set_const("TRIGGER_MODE_TRIGGERED", Oscilloscope::TRIGGER_MODE_TRIGGERED);
    mod.set_const("TRIGGER_MODE_WAIT", Oscilloscope::TRIGGER_MODE_WAIT);
    mod.set_const("TRIGGER_MODE_AUTO", Oscilloscope::TRIGGER_MODE_AUTO);
    mod.set_const("TRIGGER_MODE_COUNT", Oscilloscope::TRIGGER_MODE_COUNT);

    mod.add_bits<Oscilloscope::SamplingMode>("SamplingMode", jlcxx::julia_type("CppEnum"));
    mod.set_const("REAL_TIME", Oscilloscope::REAL_TIME);
    mod.set_const("EQUIVALENT_TIME", Oscilloscope::EQUIVALENT_TIME);

    mod.add_type<Oscilloscope>("Oscilloscope", jlcxx::julia_base_type<Instrument>())
        .method("IDPing", &Oscilloscope::IDPing)
        .method("FlushConfigCache", &Oscilloscope::FlushConfigCache)
        .method("IsOffline", &Oscilloscope::IsOffline)
        .method("GetChannelCount", &Oscilloscope::GetChannelCount)
        .method("GetChannel", &Oscilloscope::GetChannel)
        .method("GetChannelByDisplayName", &Oscilloscope::GetChannelByDisplayName)
        .method("GetChannelByHwName", &Oscilloscope::GetChannelByHwName)
        .method("IsChannelEnabled", &Oscilloscope::IsChannelEnabled)
        .method("EnableChannel", &Oscilloscope::EnableChannel)
        .method("CanEnableChannel", &Oscilloscope::CanEnableChannel)
        .method("DisableChannel", &Oscilloscope::DisableChannel)
        .method("GetChannelCoupling", &Oscilloscope::GetChannelCoupling)
        .method("SetChannelCoupling", &Oscilloscope::SetChannelCoupling)
        // .method("GetAvailableCouplings", &Oscilloscope::GetAvailableCouplings)
        .method("GetChannelDisplayName", &Oscilloscope::GetChannelDisplayName)
        .method("SetChannelDisplayName", &Oscilloscope::SetChannelDisplayName)
        .method("GetChannelAttenuation", &Oscilloscope::GetChannelAttenuation)
        .method("SetChannelAttenuation", &Oscilloscope::SetChannelAttenuation)
        .method("GetChannelBandwidthLimiters", &Oscilloscope::GetChannelBandwidthLimiters)
        .method("GetChannelBandwidthLimit", &Oscilloscope::GetChannelBandwidthLimit)
        .method("SetChannelBandwidthLimit", &Oscilloscope::SetChannelBandwidthLimit)
        .method("GetExternalTrigger", &Oscilloscope::GetExternalTrigger)
        .method("GetChannelVoltageRange", &Oscilloscope::GetChannelVoltageRange)
        .method("SetChannelVoltageRange", &Oscilloscope::SetChannelVoltageRange)
        .method("CanAutoZero", &Oscilloscope::CanAutoZero)
        .method("AutoZero", &Oscilloscope::AutoZero)
        .method("GetProbeName", &Oscilloscope::GetProbeName)
        .method("HasInputMux", &Oscilloscope::HasInputMux)
        .method("GetInputMuxSetting", &Oscilloscope::GetInputMuxSetting)
        // .method("GetInputMuxNames", &Oscilloscope::GetInputMuxNames)
        .method("SetInputMux", &Oscilloscope::SetInputMux)
        .method("GetChannelOffset", &Oscilloscope::GetChannelOffset)
        .method("SetChannelOffset", &Oscilloscope::SetChannelOffset)
        .method("CanInvert", &Oscilloscope::CanInvert)
        .method("Invert", &Oscilloscope::Invert)
        .method("IsInverted", &Oscilloscope::IsInverted)
        .method("PollTrigger", &Oscilloscope::PollTrigger)
        .method("PeekTriggerArmed", &Oscilloscope::PeekTriggerArmed)
        .method("WaitForTrigger", &Oscilloscope::WaitForTrigger)
        .method("SetTrigger", &Oscilloscope::SetTrigger)
        .method("PushTrigger", &Oscilloscope::PushTrigger)
        .method("GetTrigger", &Oscilloscope::GetTrigger)
        .method("PullTrigger", &Oscilloscope::PullTrigger)
        // .method("GetTriggerTypes", &Oscilloscope::GetTriggerTypes)
        .method("AcquireData", &Oscilloscope::AcquireData)
        .method("Start", &Oscilloscope::Start)
        .method("StartSingleTrigger", &Oscilloscope::StartSingleTrigger)
        .method("Stop", &Oscilloscope::Stop)
        .method("ForceTrigger", &Oscilloscope::ForceTrigger)
        .method("IsTriggerArmed", &Oscilloscope::IsTriggerArmed)
        .method("EnableTriggerOutput", &Oscilloscope::EnableTriggerOutput)
        .method("GetTransportConnectionString", &Oscilloscope::GetTransportConnectionString)
        .method("GetTransportName", &Oscilloscope::GetTransportName)
        .method("GetSampleRatesNonInterleaved", &Oscilloscope::GetSampleRatesNonInterleaved)
        .method("GetSampleRatesInterleaved", &Oscilloscope::GetSampleRatesInterleaved)
        .method("GetSampleRate", &Oscilloscope::GetSampleRate)
        .method("IsInterleaving", &Oscilloscope::IsInterleaving)
        .method("SetInterleaving", &Oscilloscope::SetInterleaving)
        .method("CanInterleave", &Oscilloscope::CanInterleave)
        // .method("GetInterleaveConflicts", &Oscilloscope::GetInterleaveConflicts)
        .method("GetSampleDepthsNonInterleaved", &Oscilloscope::GetSampleDepthsNonInterleaved)
        .method("GetSampleDepthsInterleaved", &Oscilloscope::GetSampleDepthsInterleaved)
        .method("GetSampleDepth", &Oscilloscope::GetSampleDepth)
        .method("SetSampleDepth", &Oscilloscope::SetSampleDepth)
        .method("SetSampleRate", &Oscilloscope::SetSampleRate)
        .method("IsSamplingModeAvailable", &Oscilloscope::IsSamplingModeAvailable)
        .method("GetSamplingMode", &Oscilloscope::GetSamplingMode)
        .method("SetSamplingMode", &Oscilloscope::SetSamplingMode)
        .method("SetUseExternalRefclk", &Oscilloscope::SetUseExternalRefclk)
        .method("SetTriggerOffset", &Oscilloscope::SetTriggerOffset)
        .method("GetTriggerOffset", &Oscilloscope::GetTriggerOffset)
        .method("SetDeskewForChannel", &Oscilloscope::SetDeskewForChannel)
        .method("GetDeskewForChannel", &Oscilloscope::GetDeskewForChannel)
        // .method("GetAnalogBanks", &Oscilloscope::GetAnalogBanks)
        // .method("GetAnalogBank", &Oscilloscope::GetAnalogBank)
        .method("IsADCModeConfigurable", &Oscilloscope::IsADCModeConfigurable)
        // .method("GetADCModeNames", &Oscilloscope::GetADCModeNames)
        .method("GetADCMode", &Oscilloscope::GetADCMode)
        .method("SetADCMode", &Oscilloscope::SetADCMode)
        // .method("GetDigitalBanks", &Oscilloscope::GetDigitalBanks)
        // .method("GetDigitalBank", &Oscilloscope::GetDigitalBank)
        .method("IsDigitalHysteresisConfigurable", &Oscilloscope::IsDigitalHysteresisConfigurable)
        .method("IsDigitalThresholdConfigurable", &Oscilloscope::IsDigitalThresholdConfigurable)
        .method("GetDigitalHysteresis", &Oscilloscope::GetDigitalHysteresis)
        .method("GetDigitalThreshold", &Oscilloscope::GetDigitalThreshold)
        .method("SetDigitalHysteresis", &Oscilloscope::SetDigitalHysteresis)
        .method("SetDigitalThreshold", &Oscilloscope::SetDigitalThreshold)
        .method("SetSpan", &Oscilloscope::SetSpan)
        .method("GetSpan", &Oscilloscope::GetSpan)
        .method("SetCenterFrequency", &Oscilloscope::SetCenterFrequency)
        .method("GetCenterFrequency", &Oscilloscope::GetCenterFrequency)
        .method("SetResolutionBandwidth", &Oscilloscope::SetResolutionBandwidth)
        .method("GetResolutionBandwidth", &Oscilloscope::GetResolutionBandwidth)
        .method("HasFrequencyControls", &Oscilloscope::HasFrequencyControls)
        // .method("SerializeConfiguration", &Oscilloscope::SerializeConfiguration)
        // .method("LoadConfiguration", &Oscilloscope::LoadConfiguration)
        .method("HasPendingWaveforms", &Oscilloscope::HasPendingWaveforms)
        .method("ClearPendingWaveforms", &Oscilloscope::ClearPendingWaveforms)
        .method("GetPendingWaveformCount", &Oscilloscope::GetPendingWaveformCount)
        .method("PopPendingWaveform", &Oscilloscope::PopPendingWaveform)
        // .method("DoAddDriverClass", &Oscilloscope::DoAddDriverClass)
        .method("EnumDrivers", &Oscilloscope::EnumDrivers)
        .method("CreateOscilloscope", &Oscilloscope::CreateOscilloscope)
        .method("GetDriverName", &Oscilloscope::GetDriverName);

    mod.add_bits<FunctionGenerator::WaveShape>("WaveShape", jlcxx::julia_type("CppEnum"));
    mod.set_const("SHAPE_SINE", FunctionGenerator::SHAPE_SINE);
    mod.set_const("SHAPE_SQUARE", FunctionGenerator::SHAPE_SQUARE);
    mod.set_const("SHAPE_TRIANGLE", FunctionGenerator::SHAPE_TRIANGLE);
    mod.set_const("SHAPE_PULSE", FunctionGenerator::SHAPE_PULSE);
    mod.set_const("SHAPE_DC", FunctionGenerator::SHAPE_DC);
    mod.set_const("SHAPE_NOISE", FunctionGenerator::SHAPE_NOISE);
    mod.set_const("SHAPE_ARB", FunctionGenerator::SHAPE_ARB);

    mod.add_type<FunctionGenerator>("FunctionGenerator", jlcxx::julia_base_type<Instrument>())
        .method("GetFunctionChannelCount", &FunctionGenerator::GetFunctionChannelCount)
        .method("GetFunctionChannelName", &FunctionGenerator::GetFunctionChannelName)
        .method("GetFunctionChannelActive", &FunctionGenerator::GetFunctionChannelActive)
        .method("SetFunctionChannelActive", &FunctionGenerator::SetFunctionChannelActive)
        .method("GetFunctionChannelDutyCycle", &FunctionGenerator::GetFunctionChannelDutyCycle)
        .method("SetFunctionChannelDutyCycle", &FunctionGenerator::SetFunctionChannelDutyCycle)
        .method("GetFunctionChannelAmplitude", &FunctionGenerator::GetFunctionChannelAmplitude)
        .method("SetFunctionChannelAmplitude", &FunctionGenerator::SetFunctionChannelAmplitude)
        .method("GetFunctionChannelOffset", &FunctionGenerator::GetFunctionChannelOffset)
        .method("SetFunctionChannelOffset", &FunctionGenerator::SetFunctionChannelOffset)
        .method("GetFunctionChannelFrequency", &FunctionGenerator::GetFunctionChannelFrequency)
        .method("SetFunctionChannelFrequency", &FunctionGenerator::SetFunctionChannelFrequency)
        .method("GetFunctionChannelShape", &FunctionGenerator::GetFunctionChannelShape)
        .method("SetFunctionChannelShape", &FunctionGenerator::SetFunctionChannelShape)
        .method("GetFunctionChannelRiseTime", &FunctionGenerator::GetFunctionChannelRiseTime)
        .method("SetFunctionChannelRiseTime", &FunctionGenerator::SetFunctionChannelRiseTime)
        .method("GetFunctionChannelFallTime", &FunctionGenerator::GetFunctionChannelFallTime)
        .method("SetFunctionChannelFallTime", &FunctionGenerator::SetFunctionChannelFallTime);

    mod.method("TransportStaticInit", &TransportStaticInit);
    mod.method("DriverStaticInit", &DriverStaticInit);

    mod.method("AnalogWaveformData", &AnalogWaveformData);
    mod.method("GetFunctionGenerator", &GetFunctionGenerator);
}
