unit SimRegister;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  // Batch 1
  SimIndicators, SimInputs, SimGauges, SimAvionics, SimContainers,
  // Batch 2
  SimFader, SimPushButton, SimLedBarGraph, SimOscilloscope, SimRadarScreen,
  SimMatrixPad, SimSelectorSwitch, SimThrottleLever, SimJoystick,
  SimLcdDisplay, SimSafetySwitch, SimAudioJack;

procedure Register;

implementation

{$R SkeuoSimControls.res}

procedure Register;
begin
  RegisterComponents('SkeuoSim', [
    // Batch 1
    TLEDIndicator,
    TSevenSegment,
    TKnob,
    TSimToggleSwitch,
    TCircularGauge,
    TLinearGauge,
    TVuMeter,
    TCompass,
    TAviatorGauge,
    TSimGroupBox,

    // Batch 2
    TSimFader,
    TSimPushButton,
    TSimLedBarGraph,
    TSimOscilloscope,
    TSimRadarScreen,
    TSimMatrixPad,
    TSimSelectorSwitch,
    TSimThrottleLever,
    TSimJoystick,
    TSimLcdDisplay,
    TSimSafetySwitch,
    TSimAudioJack
  ]);
end;

end.
