unit SimAudioJack;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  { TSimAudioJack }
  TSimAudioJack = class(TSimCustomControl)
  private
    FIsPlugged: Boolean;
    FBaseColor: TColor;
    FCableColor: TColor;
    FOnChange: TNotifyEvent;

    procedure SetIsPlugged(AValue: Boolean);
    procedure SetBaseColor(AValue: TColor);
    procedure SetCableColor(AValue: TColor);
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property IsPlugged: Boolean read FIsPlugged write SetIsPlugged default False;
    property BaseColor: TColor read FBaseColor write SetBaseColor default $00202020;
    property CableColor: TColor read FCableColor write SetCableColor default clMaroon;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    property Align;
    property Anchors;
    property Visible;
    property Enabled;
    property Width default 60;
    property Height default 80;
  end;

implementation

{ ==============================================================================
  TSimAudioJack
  ============================================================================== }

constructor TSimAudioJack.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 60;
  Height := 80;
  FIsPlugged := False;
  FBaseColor := $00202020;
  FCableColor := clMaroon;
end;

procedure TSimAudioJack.SetIsPlugged(AValue: Boolean);
begin
  if FIsPlugged = AValue then Exit;
  FIsPlugged := AValue;
  Invalidate;
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TSimAudioJack.SetBaseColor(AValue: TColor);
begin
  if FBaseColor = AValue then Exit;
  FBaseColor := AValue;
  InvalidateBackground;
end;

procedure TSimAudioJack.SetCableColor(AValue: TColor);
begin
  if FCableColor = AValue then Exit;
  FCableColor := AValue;
  if FIsPlugged then Invalidate;
end;

procedure TSimAudioJack.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
    SetIsPlugged(not FIsPlugged);
end;

procedure TSimAudioJack.DrawBackground(ABitmap: TBGRABitmap);
var
  CX, CY, Radius, HoleRadius, A: Single;
  i: Integer;
  HexPts: array[0..5] of TPointF;
  GradScanner: IBGRAScanner;
  BaseC: TBGRAPixel;
begin
  inherited DrawBackground(ABitmap);

  CX := Width / 2;
  CY := 30; // Posisi jack agak ke atas memberi ruang untuk kabel jatuh
  Radius := Min(Width, 60) / 2 - 4;
  HoleRadius := Radius * 0.45;

  // 1. Bayangan Jatuh (Drop Shadow)
  ABitmap.FillEllipseAntialias(CX, CY + 4, Radius, Radius, BGRA(0, 0, 0, 150));

  // 2. Base Washer (Cincin Plastik/Besi Dasar)
  BaseC := ColorToBGRA(ColorToRGB(FBaseColor));
  ABitmap.FillEllipseAntialias(CX, CY, Radius, Radius, BaseC);
  ABitmap.EllipseAntialias(CX, CY, Radius, Radius, BGRA(0, 0, 0, 200), 1.0);

  // Highlight Dasar
  ABitmap.DrawLineAntialias(CX - Radius + 2, CY - Radius + 2, CX + Radius - 2, CY - Radius + 2, BGRA(255, 255, 255, 50), 2.0);

  // 3. Hex Nut (Mur Segi Enam Penahan Jack)
  for i := 0 to 5 do
  begin
    A := DegToRad((i * 60) + 30);
    HexPts[i] := PointF(CX + Cos(A) * (Radius * 0.75), CY + Sin(A) * (Radius * 0.75));
  end;

  GradScanner := TBGRAGradientScanner.Create(
    BGRA(210, 210, 210, 255), BGRA(90, 90, 90, 255),
    gtLinear, PointF(CX, CY - Radius), PointF(CX, CY + Radius));

  ABitmap.FillPolyAntialias(HexPts, GradScanner);
  ABitmap.DrawPolyLineAntialias(HexPts, BGRA(40, 40, 40, 255), 1.5, True);

  // 4. Lubang Jack (Socket Hole)
  // Outer Ring Lubang
  ABitmap.FillEllipseAntialias(CX, CY, HoleRadius + 2, HoleRadius + 2, BGRA(40, 40, 40, 255));
  // Lubang Gelap Dalam
  ABitmap.FillEllipseAntialias(CX, CY, HoleRadius, HoleRadius, BGRA(10, 10, 10, 255));

  // Inner Shadow Lubang
  ABitmap.DrawLineAntialias(CX - HoleRadius, CY - HoleRadius, CX + HoleRadius, CY - HoleRadius, BGRA(0, 0, 0, 200), 2.0);
  ABitmap.DrawLineAntialias(CX - HoleRadius, CY, CX - HoleRadius, CY + HoleRadius, BGRA(0, 0, 0, 200), 2.0);
end;

procedure TSimAudioJack.DrawForeground(ABitmap: TBGRABitmap);
var
  CX, CY, PlugRadius, PlugLength: Single;
  GradScanner: IBGRAScanner;
  CabC: TBGRAPixel;
  R, G, B: Byte;
begin
  inherited DrawForeground(ABitmap);

  if not FIsPlugged then Exit;

  CX := Width / 2;
  CY := 30;
  PlugRadius := (Min(Width, 60) / 2 - 4) * 0.45 + 1; // Sedikit lebih besar dari lubang
  PlugLength := 25.0;

  // 1. Kabel Menggantung (Bezier Curve)
  CabC := ColorToBGRA(ColorToRGB(FCableColor));
  R := CabC.red; G := CabC.green; B := CabC.blue;

  // Bayangan Kabel
  ABitmap.DrawLineAntialias(CX + 2, CY + PlugLength, CX + 2, Height + 10, BGRA(0, 0, 0, 120), 8.0);

  // Badan Kabel
  ABitmap.DrawLineAntialias(CX, CY + PlugLength - 5, CX, Height + 10, BGRA(Max(0, R-50), Max(0, G-50), Max(0, B-50), 255), 8.0);
  ABitmap.DrawLineAntialias(CX, CY + PlugLength - 5, CX, Height + 10, CabC, 6.0);

  // Highlight Kabel
  ABitmap.DrawLineAntialias(CX - 1, CY + PlugLength, CX - 1, Height + 10, BGRA(255, 255, 255, 60), 2.0);

  // 2. Karet Pelindung Pangkal Kabel (Strain Relief)
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(50, 50, 50, 255), BGRA(10, 10, 10, 255),
    gtLinear, PointF(CX - PlugRadius * 0.8, CY), PointF(CX + PlugRadius * 0.8, CY));
  ABitmap.FillRoundRectAntialias(CX - PlugRadius * 0.7, CY + PlugLength - 2, CX + PlugRadius * 0.7, CY + PlugLength + 15, 2, 2, GradScanner);

  // Grip pelindung (Garis-garis horizontal)
  ABitmap.DrawLineAntialias(CX - PlugRadius * 0.7, CY + PlugLength + 3, CX + PlugRadius * 0.7, CY + PlugLength + 3, BGRA(0, 0, 0, 200), 1.0);
  ABitmap.DrawLineAntialias(CX - PlugRadius * 0.7, CY + PlugLength + 7, CX + PlugRadius * 0.7, CY + PlugLength + 7, BGRA(0, 0, 0, 200), 1.0);
  ABitmap.DrawLineAntialias(CX - PlugRadius * 0.7, CY + PlugLength + 11, CX + PlugRadius * 0.7, CY + PlugLength + 11, BGRA(0, 0, 0, 200), 1.0);

  // 3. Badan Plug (Gagang)
  // Drop Shadow Gagang
  ABitmap.FillRoundRectAntialias(CX - PlugRadius + 4, CY + 4, CX + PlugRadius + 4, CY + PlugLength + 4, 3, 3, BGRA(0, 0, 0, 150));

  // Material Gagang
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(Min(255, R+40), Min(255, G+40), Min(255, B+40), 255),
    BGRA(Max(0, R-60), Max(0, G-60), Max(0, B-60), 255),
    gtLinear, PointF(CX - PlugRadius, CY), PointF(CX + PlugRadius, CY));

  ABitmap.FillRoundRectAntialias(CX - PlugRadius, CY, CX + PlugRadius, CY + PlugLength, 3, 3, GradScanner);
  ABitmap.RoundRectAntialias(CX - PlugRadius, CY, CX + PlugRadius, CY + PlugLength, 3, 3, BGRA(0, 0, 0, 200), 1.0);

  // Highlight Glossy Gagang Plastik
  ABitmap.DrawLineAntialias(CX - PlugRadius * 0.5, CY + 2, CX - PlugRadius * 0.5, CY + PlugLength - 2, BGRA(255, 255, 255, 80), 2.0);
end;

end.
