unit SimRadarScreen;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  { TSimRadarScreen }
  TSimRadarScreen = class(TSimGraphicControl)
  private
    FSweepAngle: Single;
    FGridColor: TColor;
    FSweepColor: TColor;
    FShowRings: Boolean;
    FShowCrosshair: Boolean;

    procedure SetSweepAngle(AValue: Single);
    procedure SetGridColor(AValue: TColor);
    procedure SetSweepColor(AValue: TColor);
    procedure SetShowRings(AValue: Boolean);
    procedure SetShowCrosshair(AValue: Boolean);
  protected
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property SweepAngle: Single read FSweepAngle write SetSweepAngle;
    property GridColor: TColor read FGridColor write SetGridColor default $00004000;
    property SweepColor: TColor read FSweepColor write SetSweepColor default clLime;
    property ShowRings: Boolean read FShowRings write SetShowRings default True;
    property ShowCrosshair: Boolean read FShowCrosshair write SetShowCrosshair default True;

    property Align;
    property Anchors;
    property Visible;
    property Width default 200;
    property Height default 200;
  end;

implementation

{ ==============================================================================
  TSimRadarScreen
  ============================================================================== }

constructor TSimRadarScreen.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 200;
  Height := 200;
  FSweepAngle := 0;
  FGridColor := $00004000; // Hijau gelap
  FSweepColor := clLime;
  FShowRings := True;
  FShowCrosshair := True;
end;

procedure TSimRadarScreen.SetSweepAngle(AValue: Single);
begin
  if FSweepAngle = AValue then Exit;
  FSweepAngle := AValue;
  while FSweepAngle >= 360 do FSweepAngle := FSweepAngle - 360;
  while FSweepAngle < 0 do FSweepAngle := FSweepAngle + 360;
  Invalidate; // Hanya memicu pembaruan Foreground (Garis Sweep)
end;

procedure TSimRadarScreen.SetGridColor(AValue: TColor);
begin
  if FGridColor = AValue then Exit;
  FGridColor := AValue;
  InvalidateBackground;
end;

procedure TSimRadarScreen.SetSweepColor(AValue: TColor);
begin
  if FSweepColor = AValue then Exit;
  FSweepColor := AValue;
  Invalidate;
end;

procedure TSimRadarScreen.SetShowRings(AValue: Boolean);
begin
  if FShowRings = AValue then Exit;
  FShowRings := AValue;
  InvalidateBackground;
end;

procedure TSimRadarScreen.SetShowCrosshair(AValue: Boolean);
begin
  if FShowCrosshair = AValue then Exit;
  FShowCrosshair := AValue;
  InvalidateBackground;
end;

procedure TSimRadarScreen.DrawBackground(ABitmap: TBGRABitmap);
var
  CX, CY, Radius, InnerRadius: Single;
  GradScanner: IBGRAScanner;
  GridC: TBGRAPixel;
  i: Integer;
  RingSpacing: Single;
begin
  inherited DrawBackground(ABitmap);

  CX := Width / 2;
  CY := Height / 2;
  Radius := Math.Min(CX, CY) - 4;
  if Radius <= 0 then Exit;

  // 1. Drop Shadow Outer
  ABitmap.FillEllipseAntialias(CX, CY + 4, Radius, Radius, BGRA(0, 0, 0, 100));

  // 2. Bezel Frame Logam
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(90, 90, 90, 255), BGRA(30, 30, 30, 255),
    gtLinear, PointF(CX - Radius, CY - Radius), PointF(CX + Radius, CY + Radius));
  ABitmap.FillEllipseAntialias(CX, CY, Radius, Radius, GradScanner);

  // 3. Layar Kaca Gelap (Latar Belakang Radar)
  InnerRadius := Radius * 0.9;
  ABitmap.FillEllipseAntialias(CX, CY, InnerRadius, InnerRadius, BGRA(5, 15, 5, 255));
  ABitmap.EllipseAntialias(CX, CY, InnerRadius, InnerRadius, BGRA(0, 0, 0, 255), 3.0);

  // 4. Gambar Graticule (Grid / Cincin)
  GridC := ColorToBGRA(ColorToRGB(FGridColor));

  if FShowRings then
  begin
    RingSpacing := InnerRadius / 4;
    for i := 1 to 3 do
    begin
      ABitmap.EllipseAntialias(CX, CY, i * RingSpacing, i * RingSpacing, GridC, 1.5);
    end;
  end;

  if FShowCrosshair then
  begin
    // Garis Vertikal dan Horizontal
    ABitmap.DrawLineAntialias(CX, CY - InnerRadius, CX, CY + InnerRadius, GridC, 1.5);
    ABitmap.DrawLineAntialias(CX - InnerRadius, CY, CX + InnerRadius, CY, GridC, 1.5);

    // Titik Pusat
    ABitmap.FillEllipseAntialias(CX, CY, 3, 3, GridC);
  end;
end;

procedure TSimRadarScreen.DrawForeground(ABitmap: TBGRABitmap);
var
  CX, CY, InnerRadius, DrawAngle: Single;
  C: TBGRAPixel;
  R, G, B: Byte;
  Alpha: Integer;
  P: TPointF;
  i: Integer;
  TailLength: Integer;
begin
  inherited DrawForeground(ABitmap);

  CX := Width / 2;
  CY := Height / 2;
  InnerRadius := (Math.Min(CX, CY) - 4) * 0.9;

  C := ColorToBGRA(ColorToRGB(FSweepColor));
  R := C.red;
  G := C.green;
  B := C.blue;

  // 1. Gambar Efek Sapuan Radar (Tail/Jejak Fosfor)
  TailLength := 60; // Jejak sepanjang 60 derajat ke belakang

  for i := TailLength downto 0 do
  begin
    // Hitung mundur sudut dari posisi saat ini
    DrawAngle := FSweepAngle - i;

    // Perhitungan Alpha (Fading/Meredup dari ujung ekor ke kepala)
    Alpha := Round(255 * (1 - (i / TailLength)));

    P := SimPointOnCircle(PointF(CX, CY), InnerRadius, DrawAngle);

    // Lebar garis diperbesar sedikit (2.0) untuk menutupi celah piksel antar sudut
    ABitmap.DrawLineAntialias(CX, CY, P.X, P.Y, BGRA(R, G, B, Alpha), 2.0);
  end;

  // 2. Garis Sapuan Utama (Leading Edge)
  P := SimPointOnCircle(PointF(CX, CY), InnerRadius, FSweepAngle);
  ABitmap.DrawLineAntialias(CX, CY, P.X, P.Y, BGRA(255, 255, 255, 200), 2.5);

  // 3. Efek Titik Terang Target Simulasi (Blips opsional untuk kosmetik)
  // Target 1
  P := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.6, 45);
  ABitmap.FillEllipseAntialias(P.X, P.Y, 4, 4, BGRA(R, G, B, 150));
  // Target 2
  P := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.8, 120);
  ABitmap.FillEllipseAntialias(P.X, P.Y, 3, 3, BGRA(R, G, B, 100));

  // 4. Efek Pantulan Kaca Radar Overlay
  ABitmap.FillEllipseAntialias(CX - InnerRadius*0.3, CY - InnerRadius*0.3,
                               InnerRadius*0.6, InnerRadius*0.4,
                               BGRA(255, 255, 255, 25));
end;

end.
