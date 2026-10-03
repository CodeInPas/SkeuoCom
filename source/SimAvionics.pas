unit SimAvionics;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Types, Math,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  { TCompass }
  TCompass = class(TSimGraphicControl)
  private
    FHeading: Extended;
    procedure SetHeading(AValue: Extended);
  protected
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Heading: Extended read FHeading write SetHeading;

    property Align;
    property Anchors;
    property Visible;
    property Font;
    property Width default 150;
    property Height default 150;
  end;

  { TAviatorGauge (Attitude Indicator) }
  TAviatorGauge = class(TSimGraphicControl)
  private
    FPitch: Extended;
    FRoll: Extended;
    FMaskBmp: TBGRABitmap;
    FCanvasBmp: TBGRABitmap;
    procedure SetPitch(AValue: Extended);
    procedure SetRoll(AValue: Extended);
    procedure RecreateBuffers;
  protected
    procedure Resize; override;
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Pitch: Extended read FPitch write SetPitch;
    property Roll: Extended read FRoll write SetRoll;

    property Align;
    property Anchors;
    property Visible;
    property Width default 150;
    property Height default 150;
  end;

implementation

{ ==============================================================================
  TCompass
  ============================================================================== }

constructor TCompass.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 150;
  Height := 150;
  FHeading := 0;
  Font.Name := 'Arial';
  Font.Style := [fsBold];
end;

procedure TCompass.SetHeading(AValue: Extended);
begin
  if FHeading = SimNormalizeAngle(AValue) then Exit;
  FHeading := SimNormalizeAngle(AValue);
  Invalidate;
end;

procedure TCompass.DrawBackground(ABitmap: TBGRABitmap);
var
  CX, CY, Radius: Single;
  GradScanner: IBGRAScanner;
begin
  inherited DrawBackground(ABitmap);
  CX := Width / 2;
  CY := Height / 2;
  Radius := Math.Min(CX, CY) - 4;
  if Radius <= 0 then Exit;

  // Outer Shadow
  ABitmap.FillEllipseAntialias(CX, CY + 3, Radius, Radius, BGRA(0, 0, 0, 100));

  // Bezel Luar
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(50, 50, 50, 255), BGRA(10, 10, 10, 255),
    gtLinear, PointF(CX - Radius, CY - Radius), PointF(CX + Radius, CY + Radius));
  ABitmap.FillEllipseAntialias(CX, CY, Radius, Radius, GradScanner);

  // Background Faceplate
  ABitmap.FillEllipseAntialias(CX, CY, Radius * 0.88, Radius * 0.88, BGRA(25, 25, 25, 255));

  // Inner Shadow
  ABitmap.EllipseAntialias(CX, CY, Radius * 0.88, Radius * 0.88, BGRA(0, 0, 0, 200), 3.0);
end;

procedure TCompass.DrawForeground(ABitmap: TBGRABitmap);
var
  CX, CY, Radius, InnerRadius: Single;
  i: Integer;
  DrawAngle, ItemAngle: Extended;
  P1, P2, PText: TPointF;
  CardLabels: array[0..3] of String = ('N', 'E', 'S', 'W');
  Lbl: String;
  Tw, Th: Integer;
  LubberPts: array[0..2] of TPointF;
begin
  inherited DrawForeground(ABitmap);
  CX := Width / 2;
  CY := Height / 2;
  Radius := Math.Min(CX, CY) - 4;
  InnerRadius := Radius * 0.88;

  ABitmap.FontHeight := Round(InnerRadius * 0.25);
  ABitmap.FontName := Font.Name;
  ABitmap.FontStyle := Font.Style;
  ABitmap.FontAntialias := True;

  // Gambar Skala & Teks (Berputar)
  for i := 0 to 35 do
  begin
    ItemAngle := i * 10;
    // 270 adalah titik atas (Top). Heading menggeser posisi berlawanan jarum jam
    DrawAngle := SimNormalizeAngle(270 - FHeading + ItemAngle);

    if i mod 9 = 0 then // N, E, S, W (Setiap 90 derajat)
    begin
      P1 := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.95, DrawAngle);
      P2 := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.75, DrawAngle);
      ABitmap.DrawLineAntialias(P1.X, P1.Y, P2.X, P2.Y, BGRA(255, 255, 255, 255), 2.5);

      Lbl := CardLabels[i div 9];
      PText := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.55, DrawAngle);
      Tw := ABitmap.TextSize(Lbl).cx;
      Th := ABitmap.TextSize(Lbl).cy;

      if Lbl = 'N' then
        ABitmap.TextOut(PText.X - Tw/2, PText.Y - Th/2, Lbl, BGRA(255, 50, 50, 255))
      else
        ABitmap.TextOut(PText.X - Tw/2, PText.Y - Th/2, Lbl, BGRA(255, 255, 255, 255));
    end
    else if i mod 3 = 0 then // Major ticks (Setiap 30 derajat)
    begin
      P1 := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.95, DrawAngle);
      P2 := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.80, DrawAngle);
      ABitmap.DrawLineAntialias(P1.X, P1.Y, P2.X, P2.Y, BGRA(200, 200, 200, 255), 1.5);
    end
    else // Minor ticks
    begin
      P1 := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.95, DrawAngle);
      P2 := SimPointOnCircle(PointF(CX, CY), InnerRadius * 0.88, DrawAngle);
      ABitmap.DrawLineAntialias(P1.X, P1.Y, P2.X, P2.Y, BGRA(150, 150, 150, 255), 1.0);
    end;
  end;

  // Indikator Statis (Lubber Line) di bagian atas
  LubberPts[0] := PointF(CX, CY - InnerRadius + 5);
  LubberPts[1] := PointF(CX - 8, CY - InnerRadius - 10);
  LubberPts[2] := PointF(CX + 8, CY - InnerRadius - 10);
  ABitmap.FillPolyAntialias(LubberPts, BGRA(255, 50, 50, 255));
  ABitmap.DrawPolyLineAntialias(LubberPts, BGRA(150, 0, 0, 255), 1, True);

  // Efek Pantulan Kaca
  ABitmap.FillEllipseAntialias(CX - Radius*0.3, CY - Radius*0.4,
                               Radius*0.5, Radius*0.3,
                               BGRA(255, 255, 255, 30));

  // Titik Poros Tengah (Estetika)
  ABitmap.FillEllipseAntialias(CX, CY, 4, 4, BGRA(150, 150, 150, 255));
end;

{ ==============================================================================
  TAviatorGauge
  ============================================================================== }

constructor TAviatorGauge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 150;
  Height := 150;
  FPitch := 0;
  FRoll := 0;
  FMaskBmp := nil;
  FCanvasBmp := nil;
end;

destructor TAviatorGauge.Destroy;
begin
  if Assigned(FMaskBmp) then FreeAndNil(FMaskBmp);
  if Assigned(FCanvasBmp) then FreeAndNil(FCanvasBmp);
  inherited Destroy;
end;

procedure TAviatorGauge.RecreateBuffers;
var
  CX, CY, Radius: Single;
begin
  if Assigned(FMaskBmp) then FreeAndNil(FMaskBmp);
  if Assigned(FCanvasBmp) then FreeAndNil(FCanvasBmp);

  if (Width <= 0) or (Height <= 0) then Exit;

  FMaskBmp := TBGRABitmap.Create(Width, Height);
  FCanvasBmp := TBGRABitmap.Create(Width, Height);

  CX := Width / 2;
  CY := Height / 2;
  Radius := Math.Min(CX, CY) - 8;

  // Membuat Mask Lingkaran (Putih solid, sisanya transparan)
  FMaskBmp.FillTransparent;
  FMaskBmp.FillEllipseAntialias(CX, CY, Radius, Radius, BGRA(255, 255, 255, 255));
end;

procedure TAviatorGauge.Resize;
begin
  inherited Resize;
  RecreateBuffers;
end;

procedure TAviatorGauge.SetPitch(AValue: Extended);
begin
  if FPitch = EnsureRange(AValue, -90, 90) then Exit;
  FPitch := EnsureRange(AValue, -90, 90);
  Invalidate;
end;

procedure TAviatorGauge.SetRoll(AValue: Extended);
begin
  if FRoll = SimNormalizeAngle(AValue + 180) - 180 then Exit;
  // Simpan dalam range -180 hingga 180
  FRoll := AValue;
  while FRoll > 180 do FRoll := FRoll - 360;
  while FRoll < -180 do FRoll := FRoll + 360;
  Invalidate;
end;

procedure TAviatorGauge.DrawBackground(ABitmap: TBGRABitmap);
var
  CX, CY, Radius: Single;
begin
  inherited DrawBackground(ABitmap);
  CX := Width / 2;
  CY := Height / 2;
  Radius := Math.Min(CX, CY) - 4;
  if Radius <= 0 then Exit;

  // Hanya gambar outer shadow (Bezel digambar di atas Foreground)
  ABitmap.FillEllipseAntialias(CX, CY + 3, Radius, Radius, BGRA(0, 0, 0, 100));
end;

procedure TAviatorGauge.DrawForeground(ABitmap: TBGRABitmap);
var
  CX, CY, Radius, InnerRadius: Single;
  PitchOffset, RRad, S, C, Ppx, LineY: Single;
  SkyPts, GndPts: array[0..3] of TPointF;
  P1, P2: TPointF;
  i, j: Integer;
begin
  inherited DrawForeground(ABitmap);
  if (not Assigned(FMaskBmp)) or (not Assigned(FCanvasBmp)) then Exit;

  CX := Width / 2;
  CY := Height / 2;
  Radius := Math.Min(CX, CY) - 4;
  InnerRadius := Radius - 4;

  FCanvasBmp.FillTransparent;

  // --- MENGHITUNG KOORDINAT HORIZON & PITCH ---
  // Konversi Pitch ke pergeseran Pixel (Asumsi 90 derajat = radius)
  PitchOffset := (FPitch / 90.0) * InnerRadius * 1.5;
  RRad := DegToRad(-FRoll);
  S := Sin(RRad);
  C := Cos(RRad);

  // Polygon Sky (Langit) - relatif terhadap tengah
  SkyPts[0] := PointF(-Width, -Height);
  SkyPts[1] := PointF(Width, -Height);
  SkyPts[2] := PointF(Width, PitchOffset);
  SkyPts[3] := PointF(-Width, PitchOffset);

  // Polygon Ground (Tanah)
  GndPts[0] := PointF(-Width, PitchOffset);
  GndPts[1] := PointF(Width, PitchOffset);
  GndPts[2] := PointF(Width, Height);
  GndPts[3] := PointF(-Width, Height);

  // Rotasi & Translasi Polygon
  for i := 0 to 3 do
  begin
    Ppx := SkyPts[i].X;
    SkyPts[i].X := CX + (Ppx * C - SkyPts[i].Y * S);
    SkyPts[i].Y := CY + (Ppx * S + SkyPts[i].Y * C);

    Ppx := GndPts[i].X;
    GndPts[i].X := CX + (Ppx * C - GndPts[i].Y * S);
    GndPts[i].Y := CY + (Ppx * S + GndPts[i].Y * C);
  end;

  // Render Langit & Tanah ke Buffer Sementara
  FCanvasBmp.FillPolyAntialias(SkyPts, BGRA(60, 150, 220, 255)); // Biru Langit
  FCanvasBmp.FillPolyAntialias(GndPts, BGRA(150, 100, 50, 255)); // Coklat Tanah

  // Garis Horizon Putih
  FCanvasBmp.DrawLineAntialias(SkyPts[3].X, SkyPts[3].Y, SkyPts[2].X, SkyPts[2].Y, BGRA(255, 255, 255, 255), 2.0);

  // Pitch Ladder (Garis Skala Pitch)
  for j := -3 to 3 do
  begin
    if j = 0 then Continue;
    // Jarak setiap 10 derajat (tergantung skala rasio)
    LineY := PitchOffset - (j * (10 / 90.0) * InnerRadius * 1.5);

    // Rotasi koordinat garis
    P1.X := CX + (-(InnerRadius*0.3) * C - LineY * S);
    P1.Y := CY + (-(InnerRadius*0.3) * S + LineY * C);
    P2.X := CX + ((InnerRadius*0.3) * C - LineY * S);
    P2.Y := CY + ((InnerRadius*0.3) * S + LineY * C);

    FCanvasBmp.DrawLineAntialias(P1.X, P1.Y, P2.X, P2.Y, BGRA(255, 255, 255, 200), 1.5);
  end;

  // --- APLIKASI MASK & BLENDING ---
  FCanvasBmp.ApplyMask(FMaskBmp);

  // PERBAIKAN: Menggunakan PutImage dengan dmDrawWithTransparency dari BGRABitmapTypes
  ABitmap.PutImage(0, 0, FCanvasBmp, dmDrawWithTransparency);

  // --- RENDER OVERLAY STATIS (Di atas masking) ---

  // Bezel Frame
  // Gambar cincin solid dengan ketebalan (2 parameter BGRA)
  ABitmap.EllipseAntialias(CX, CY, InnerRadius, InnerRadius, BGRA(50, 50, 50, 255), 4.0);

  // Simbol Pesawat (Statis di tengah)
  // Sayap kiri
  ABitmap.DrawLineAntialias(CX - (InnerRadius*0.6), CY, CX - (InnerRadius*0.1), CY, BGRA(255, 200, 0, 255), 4.0);
  ABitmap.DrawLineAntialias(CX - (InnerRadius*0.1), CY, CX - (InnerRadius*0.1), CY + (InnerRadius*0.15), BGRA(255, 200, 0, 255), 4.0);
  // Sayap kanan
  ABitmap.DrawLineAntialias(CX + (InnerRadius*0.6), CY, CX + (InnerRadius*0.1), CY, BGRA(255, 200, 0, 255), 4.0);
  ABitmap.DrawLineAntialias(CX + (InnerRadius*0.1), CY, CX + (InnerRadius*0.1), CY + (InnerRadius*0.15), BGRA(255, 200, 0, 255), 4.0);
  // Titik pusat
  ABitmap.FillEllipseAntialias(CX, CY, 4, 4, BGRA(255, 200, 0, 255));

  // Efek Kaca Cembung (Gloss)
  ABitmap.FillEllipseAntialias(CX, CY - InnerRadius*0.4,
                               InnerRadius*0.7, InnerRadius*0.5,
                               BGRA(255, 255, 255, 40));
end;

end.
