unit SimContainers;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  SimBase, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  { TSimGroupBox }
  { Komponen kontainer bergaya panel metalik industri untuk menampung komponen lain }
  TSimGroupBox = class(TSimCustomControl)
  private
    FCaption: String;
    procedure SetCaption(const AValue: String);
  protected
    procedure DrawBackground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Caption: String read FCaption write SetCaption;
    property Color default $00D0D0D0; // Warna abu-abu metalik terang

    property Align;
    property Anchors;
    property Visible;
    property Enabled;
    property Font;
    property Width default 250;
    property Height default 150;
  end;

implementation

{ ==============================================================================
  TSimGroupBox
  ============================================================================== }

constructor TSimGroupBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 250;
  Height := 150;
  Color := $00D0D0D0;
  FCaption := 'Control Panel';
  Font.Name := 'Arial';
  Font.Style := [fsBold];
  Font.Color := clBlack;
  Font.Size := 9;
end;

procedure TSimGroupBox.SetCaption(const AValue: String);
begin
  if FCaption = AValue then Exit;
  FCaption := AValue;
  InvalidateBackground; // Teks statis, cukup gambar ulang background
end;

procedure TSimGroupBox.DrawBackground(ABitmap: TBGRABitmap);
var
  BaseRect, InnerRect: TRectF;
  GradScanner: IBGRAScanner;
  C: TBGRAPixel;
  Th: Integer;
  TextX, TextY: Single;
  R, G, B: Byte;
begin
  inherited DrawBackground(ABitmap);

  BaseRect := RectF(1, 1, Width - 1, Height - 1);
  C := ColorToBGRA(ColorToRGB(Color));
  R := C.red;
  G := C.green;
  B := C.blue;

  // 1. Latar Belakang Metalik Utama
  GradScanner := TBGRAGradientScanner.Create(
    C, BGRA(Max(0, R - 40), Max(0, G - 40), Max(0, B - 40), 255),
    gtLinear, PointF(0, 0), PointF(0, Height)
  );

  // PERBAIKAN: Pisahkan Fill gradien dan Border solid
  ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 4, 4, GradScanner);
  ABitmap.RoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 4, 4, BGRA(50, 50, 50, 255), 1);

  // 2. Bezel/Highlight Luar (Kesan Panel Timbul 3D)
  ABitmap.DrawLineAntialias(BaseRect.Left + 1, BaseRect.Top + 1, BaseRect.Right - 1, BaseRect.Top + 1, BGRA(255, 255, 255, 180), 1.0);
  ABitmap.DrawLineAntialias(BaseRect.Left + 1, BaseRect.Top + 1, BaseRect.Left + 1, BaseRect.Bottom - 1, BGRA(255, 255, 255, 180), 1.0);
  ABitmap.DrawLineAntialias(BaseRect.Right - 1, BaseRect.Top + 1, BaseRect.Right - 1, BaseRect.Bottom - 1, BGRA(0, 0, 0, 100), 1.0);
  ABitmap.DrawLineAntialias(BaseRect.Left + 1, BaseRect.Bottom - 1, BaseRect.Right - 1, BaseRect.Bottom - 1, BGRA(0, 0, 0, 100), 1.0);

  // 3. Garis Sekat Panel Dalam (Inset / Groove)
  InnerRect := RectF(8, 25, Width - 8, Height - 8);

  // Shadow Garis Sekat
  ABitmap.DrawLineAntialias(InnerRect.Left, InnerRect.Top, InnerRect.Right, InnerRect.Top, BGRA(0, 0, 0, 120), 1.0);
  ABitmap.DrawLineAntialias(InnerRect.Left, InnerRect.Top, InnerRect.Left, InnerRect.Bottom, BGRA(0, 0, 0, 120), 1.0);

  // Highlight Garis Sekat
  ABitmap.DrawLineAntialias(InnerRect.Left, InnerRect.Bottom, InnerRect.Right, InnerRect.Bottom, BGRA(255, 255, 255, 150), 1.0);
  ABitmap.DrawLineAntialias(InnerRect.Right, InnerRect.Top, InnerRect.Right, InnerRect.Bottom, BGRA(255, 255, 255, 150), 1.0);

  // 4. Baut Pengunci di Keempat Sudut (Detail Skeuomorfik)
  ABitmap.FillEllipseAntialias(6, 6, 2, 2, BGRA(60, 60, 60, 255));
  ABitmap.FillEllipseAntialias(Width - 6, 6, 2, 2, BGRA(60, 60, 60, 255));
  ABitmap.FillEllipseAntialias(6, Height - 6, 2, 2, BGRA(60, 60, 60, 255));
  ABitmap.FillEllipseAntialias(Width - 6, Height - 6, 2, 2, BGRA(60, 60, 60, 255));

  // 5. Teks Judul Panel (Efek Engraved / Ukiran Timbul ke Dalam)
  if FCaption <> '' then
  begin
    ABitmap.FontName := Font.Name;
    if Abs(Font.Height) > 0 then
      ABitmap.FontHeight := Abs(Font.Height)
    else
      ABitmap.FontHeight := 12; // Default fallback

    ABitmap.FontStyle := Font.Style;
    ABitmap.FontAntialias := True;

    Th := ABitmap.TextSize(FCaption).cy;

    TextX := 12;
    TextY := 12 - (Th / 2);

    // Highlight Teks (Memberikan kesan cahaya dari atas yang memantul di tepi bawah ukiran)
    ABitmap.TextOut(TextX, TextY + 1, FCaption, BGRA(255, 255, 255, 220));
    // Teks Utama (Warna lebih gelap dari asli agar terlihat cekung)
    ABitmap.TextOut(TextX, TextY, FCaption, BGRA(40, 40, 40, 255));
  end;
end;

end.
