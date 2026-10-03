{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit SkeuoSimControls;

{$warn 5023 off : no warning about unused units}
interface

uses
  SimRegister, SimBase, SimUtils, SimIndicators, SimInputs, SimGauges, 
  SimAvionics, SimContainers, SimFader, SimPushButton, SimLedBarGraph, 
  SimOscilloscope, SimRadarScreen, SimMatrixPad, SimSelectorSwitch, 
  SimThrottleLever, SimJoystick, SimLcdDisplay, SimSafetySwitch, SimAudioJack, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('SimRegister', @SimRegister.Register);
end;

initialization
  RegisterPackage('SkeuoSimControls', @Register);
end.
