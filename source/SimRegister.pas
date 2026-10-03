unit SimRegister;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  SimIndicators, SimInputs, SimGauges, SimAvionics, SimContainers;

procedure Register;

implementation

{$R SkeuoSimControls.res}

procedure Register;
begin
  RegisterComponents('SkeuoSim', [
    TLEDIndicator,
    TSevenSegment,
    TKnob,
    TSimToggleSwitch,
    TCircularGauge,
    TLinearGauge,
    TVuMeter,
    TCompass,
    TAviatorGauge,
    TSimGroupBox
  ]);
end;

end.
