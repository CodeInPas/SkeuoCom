unit SimIndicators;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Types, Math, SimBase, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  TLEDState = (lsOff, lsOn);

  { TLEDIndicator }
  { Komponen lampu indikator bergaya skeuomorphic dengan efek pantulan kaca }
  TLEDIndicator = class(TSimGraphicControl)
  private
    FState: TLEDState;
    FOnColor: TColor;
    FOffColor: TColor;
    procedure SetState(AValue: TLEDState);
    procedure SetOnColor(AValue: TColor);
    procedure SetOffColor(AValue: TColor);
  protected
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property State: TLEDState read FState write SetState default lsOff;
    property OnColor: TColor read FOnColor write SetOnColor default clLime;
    property OffColor: TColor read FOffColor write SetOffColor default $00004000;
    property Align;
    property Anchors;
    property Visible;
    property Width default 32;
    property Height default 32;
  end;

  { TSevenSegment }
  { Komponen layar 7-segmen klasik dengan tampilan latar redup dan glow }
  TSevenSegment = class(TSimGraphicControl)
  private
    FValue: Integer;
    FDigits: Integer;
    FOnColor: TColor;
    FOffColor: TColor;
    FPanelColor: TColor;
    procedure SetValue(AValue: Integer);
    procedure SetDigits(AValue: Integer);
    procedure SetOnColor(AValue: TColor);
    procedure SetOffColor(AValue: TColor);
    procedure SetPanelColor(AValue: TColor);
    procedure DrawDigit(ABitmap: TBGRABitmap; X, Y, W, H: Single; ANumber: Integer; AColor: TBGRAPixel);
  protected
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Value: Integer read FValue write SetValue default 0;
    property Digits: Integer read FDigits write SetDigits default 3;
    property OnColor: TColor read FOnColor write SetOnColor default clRed;
    property OffColor: TColor read FOffColor write SetOffColor default $00000044; // Merah sangat gelap
    property PanelColor: TColor read FPanelColor write SetPanelColor default clBlack;
    property Align;
    property Anchors;
    property Visible;
    property Width default 100;
    property Height default 40;
  end;

implementation

{ ==============================================================================
  TLEDIndicator
  ============================================================================== }

constructor TLEDIndicator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 32;
  Height := 32;
  FState := lsOff;
  FOnColor := clLime;
  FOffColor := $00004000; // Hijau gelap
end;

procedure TLEDIndicator.SetState(AValue: TLEDState);
begin
  if FState = AValue then Exit;
  FState := AValue;
  Invalidate; // Hanya memicu DrawForeground
end;

procedure TLEDIndicator.SetOnColor(AValue: TColor);
begin
  if FOnColor = AValue then Exit;
  FOnColor := AValue;
  Invalidate;
end;

procedure TLEDIndicator.SetOffColor(AValue: TColor);
begin
  if FOffColor = AValue then Exit;
  FOffColor := AValue;
  Invalidate;
end;

procedure TLEDIndicator.DrawBackground(ABitmap: TBGRABitmap);
var
  CX, CY, Radius, BezelInnerRad: Single;
  GradScanner: IBGRAScanner;
begin
  inherited DrawBackground(ABitmap);

  CX := Width / 2;
  CY := Height / 2;
  if CX < CY then Radius := CX - 2 else Radius := CY - 2;
  if Radius <= 0 then Exit;

  // 1. Gambar Drop Shadow LED
  ABitmap.FillEllipseAntialias(CX, CY + 1, Radius, Radius, BGRA(0, 0, 0, 100));

  // 2. Gambar Bingkai Metalik Luar (Bezel) menggunakan Gradien Linear
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(230, 230, 230, 255), BGRA(100, 100, 100, 255),
    gtLinear, PointF(CX - Radius, CY - Radius), PointF(CX + Radius, CY + Radius));
  ABitmap.FillEllipseAntialias(CX, CY, Radius, Radius, GradScanner);

  // 3. Gambar Lekukan Dalam Bezel (Inner Shadow Bezel)
  BezelInnerRad := Radius * 0.8;
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(50, 50, 50, 255), BGRA(200, 200, 200, 255),
    gtLinear, PointF(CX - BezelInnerRad, CY - BezelInnerRad), PointF(CX + BezelInnerRad, CY + BezelInnerRad));
  ABitmap.FillEllipseAntialias(CX, CY, BezelInnerRad, BezelInnerRad, GradScanner);
end;

procedure TLEDIndicator.DrawForeground(ABitmap: TBGRABitmap);
var
  CX, CY, BulbRadius: Single;
  BaseColor: TColor;
  GradScanner: IBGRAScanner;
  C1, C2: TBGRAPixel;
begin
  inherited DrawForeground(ABitmap);

  CX := Width / 2;
  CY := Height / 2;
  if CX < CY then BulbRadius := CX - 2 else BulbRadius := CY - 2;
  BulbRadius := BulbRadius * 0.75;
  if BulbRadius <= 0 then Exit;

  if FState = lsOn then BaseColor := FOnColor else BaseColor := FOffColor;

  // Menyiapkan warna gradien: Tengah lebih terang (Lighten) dari warna dasar
  C1 := ColorToBGRA(ColorToRGB(BaseColor));
  C2 := ColorToBGRA(ColorToRGB(BaseColor));

  if FState = lsOn then
  begin
    C1.Lightness := Min(65535, C1.Lightness + 20000); // Glow di tengah saat menyala
  end else
  begin
    C1.Lightness := C1.Lightness + 5000; // Sedikit lebih terang di tengah saat mati
    C2.Lightness := Max(0, C2.Lightness - 15000); // Tepi lebih gelap saat mati
  end;

  // 1. Gambar Kaca LED (Bulb) menggunakan Gradien Radial
  GradScanner := TBGRAGradientScanner.Create(
    C1, C2, gtRadial,
    PointF(CX - BulbRadius*0.2, CY - BulbRadius*0.2),
    PointF(CX - BulbRadius*0.2 + BulbRadius, CY - BulbRadius*0.2));
  ABitmap.FillEllipseAntialias(CX, CY, BulbRadius, BulbRadius, GradScanner);

  // 2. Efek Pantulan Cahaya (Specular Glass Highlight)
  ABitmap.FillEllipseAntialias(CX - BulbRadius*0.3, CY - BulbRadius*0.4,
                               BulbRadius*0.4, BulbRadius*0.2,
                               BGRA(255, 255, 255, 120));
end;

{ ==============================================================================
  TSevenSegment
  ============================================================================== }

constructor TSevenSegment.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 100;
  Height := 40;
  FValue := 0;
  FDigits := 3;
  FOnColor := clRed;
  FOffColor := $00000044; // Warna redup latar digit
  FPanelColor := clBlack;
end;

procedure TSevenSegment.SetValue(AValue: Integer);
begin
  if FValue = AValue then Exit;
  FValue := AValue;
  Invalidate; // Update angka, tidak perlu gambar ulang background panel
end;

procedure TSevenSegment.SetDigits(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  if FDigits = AValue then Exit;
  FDigits := AValue;
  InvalidateBackground; // Update background karena tata letak digit berubah
end;

procedure TSevenSegment.SetOnColor(AValue: TColor);
begin
  if FOnColor = AValue then Exit;
  FOnColor := AValue;
  Invalidate;
end;

procedure TSevenSegment.SetOffColor(AValue: TColor);
begin
  if FOffColor = AValue then Exit;
  FOffColor := AValue;
  InvalidateBackground;
end;

procedure TSevenSegment.SetPanelColor(AValue: TColor);
begin
  if FPanelColor = AValue then Exit;
  FPanelColor := AValue;
  InvalidateBackground;
end;

procedure TSevenSegment.DrawDigit(ABitmap: TBGRABitmap; X, Y, W, H: Single; ANumber: Integer; AColor: TBGRAPixel);
const
  // Bitmask Segmen: A=1, B=2, C=4, D=8, E=16, F=32, G=64
  DigitMasks: array[0..9] of Byte = (63, 6, 91, 79, 102, 109, 125, 7, 127, 111);
var
  Thick, G: Single;
  Mask: Byte;

  procedure DrawPolygon(Pts: array of TPointF);
  begin
    ABitmap.FillPolyAntialias(Pts, AColor);
  end;

begin
  if (ANumber < 0) or (ANumber > 9) then Mask := 0 else Mask := DigitMasks[ANumber];
  if Mask = 0 then Exit;

  Thick := Min(W, H) * 0.15; // Ketebalan segmen (dinamis sesuai ukuran)
  G := Thick * 0.1; // Gap antar segmen

  // A (Atas)
  if (Mask and 1) <> 0 then
    DrawPolygon([PointF(X + Thick + G, Y), PointF(X + W - Thick - G, Y),
                 PointF(X + W - Thick*1.5 - G, Y + Thick), PointF(X + Thick*1.5 + G, Y + Thick)]);
  // B (Kanan Atas)
  if (Mask and 2) <> 0 then
    DrawPolygon([PointF(X + W, Y + Thick + G), PointF(X + W, Y + H/2 - G),
                 PointF(X + W - Thick, Y + H/2 - G - Thick*0.5), PointF(X + W - Thick, Y + Thick*1.5 + G)]);
  // C (Kanan Bawah)
  if (Mask and 4) <> 0 then
    DrawPolygon([PointF(X + W, Y + H/2 + G), PointF(X + W, Y + H - Thick - G),
                 PointF(X + W - Thick, Y + H - Thick*1.5 - G), PointF(X + W - Thick, Y + H/2 + G + Thick*0.5)]);
  // D (Bawah)
  if (Mask and 8) <> 0 then
    DrawPolygon([PointF(X + Thick*1.5 + G, Y + H - Thick), PointF(X + W - Thick*1.5 - G, Y + H - Thick),
                 PointF(X + W - Thick - G, Y + H), PointF(X + Thick + G, Y + H)]);
  // E (Kiri Bawah)
  if (Mask and 16) <> 0 then
    DrawPolygon([PointF(X, Y + H/2 + G), PointF(X, Y + H - Thick - G),
                 PointF(X + Thick, Y + H - Thick*1.5 - G), PointF(X + Thick, Y + H/2 + G + Thick*0.5)]);
  // F (Kiri Atas)
  if (Mask and 32) <> 0 then
    DrawPolygon([PointF(X, Y + Thick + G), PointF(X, Y + H/2 - G),
                 PointF(X + Thick, Y + H/2 - G - Thick*0.5), PointF(X + Thick, Y + Thick*1.5 + G)]);
  // G (Tengah)
  if (Mask and 64) <> 0 then
    DrawPolygon([PointF(X + Thick + G, Y + H/2), PointF(X + Thick*1.5 + G, Y + H/2 - Thick*0.5),
                 PointF(X + W - Thick*1.5 - G, Y + H/2 - Thick*0.5), PointF(X + W - Thick - G, Y + H/2),
                 PointF(X + W - Thick*1.5 - G, Y + H/2 + Thick*0.5), PointF(X + Thick*1.5 + G, Y + H/2 + Thick*0.5)]);
end;

procedure TSevenSegment.DrawBackground(ABitmap: TBGRABitmap);
var
  i: Integer;
  DigitW, DigitH, Space, StartX, StartY: Single;
  OffCol: TBGRAPixel;
begin
  inherited DrawBackground(ABitmap);

  // Gambar Panel Latar Belakang (Glass Panel)
  ABitmap.RoundRectAntialias(0, 0, Width, Height, 3, 3, ColorToBGRA(ColorToRGB(FPanelColor)), 1, ColorToBGRA(ColorToRGB(FPanelColor)));

  // Efek pantulan pada panel
  ABitmap.RoundRectAntialias(2, 2, Width-2, Height*0.4, 2, 2, BGRA(255, 255, 255, 10), 0, BGRA(255, 255, 255, 10));

  OffCol := ColorToBGRA(ColorToRGB(FOffColor));
  DigitH := Height * 0.8;
  DigitW := DigitH * 0.6; // Rasio standar 7-segmen
  Space := DigitW * 0.2;

  // Total lebar dari semua digit ditambah spasi
  StartX := Width - (DigitW * FDigits) - (Space * (FDigits - 1)) - (Width * 0.05);
  StartY := (Height - DigitH) / 2;

  // Gambar segmen mati (bayangan digit) untuk memperkuat kesan realistis
  for i := 0 to FDigits - 1 do
  begin
    DrawDigit(ABitmap, StartX + i * (DigitW + Space), StartY, DigitW, DigitH, 8, OffCol);
  end;
end;

procedure TSevenSegment.DrawForeground(ABitmap: TBGRABitmap);
var
  i, Val, DigitVal: Integer;
  DigitW, DigitH, Space, StartX, StartY: Single;
  OnCol: TBGRAPixel;
  SVal: String;
begin
  inherited DrawForeground(ABitmap);

  OnCol := ColorToBGRA(ColorToRGB(FOnColor));
  DigitH := Height * 0.8;
  DigitW := DigitH * 0.6;
  Space := DigitW * 0.2;

  StartX := Width - (DigitW * FDigits) - (Space * (FDigits - 1)) - (Width * 0.05);
  StartY := (Height - DigitH) / 2;

  SVal := IntToStr(FValue);

  // Menggambar dari digit paling kanan ke kiri
  for i := FDigits - 1 downto 0 do
  begin
    if Length(SVal) >= (FDigits - i) then
      DigitVal := StrToInt(SVal[Length(SVal) - (FDigits - 1 - i)])
    else
      DigitVal := -1; // Tidak digambar (kosong) di sisi kiri jika nilai lebih kecil dari jumlah digit

    if DigitVal >= 0 then
      DrawDigit(ABitmap, StartX + i * (DigitW + Space), StartY, DigitW, DigitH, DigitVal, OnCol);
  end;
end;

end.
