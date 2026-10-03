{ ==============================================================================
  File: SimPushButton.pas
  Deskripsi: Komponen tombol tekan (Push Button) industri dengan desain
             skeuomorphic. Mendukung bentuk bulat (Round) dan kotak (Rectangular).
  ============================================================================== }

unit SimPushButton;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  TSimButtonShape = (sbsRound, sbsRectangular);

  { TSimPushButton }
  TSimPushButton = class(TSimCustomControl)
  private
    FCaption: String;
    FButtonColor: TColor;
    FShape: TSimButtonShape;

    FPressed: Boolean;
    FHovered: Boolean;

    procedure SetCaption(const AValue: String);
    procedure SetButtonColor(AValue: TColor);
    procedure SetShape(AValue: TSimButtonShape);
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;

    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Caption: String read FCaption write SetCaption;
    property ButtonColor: TColor read FButtonColor write SetButtonColor default clMaroon;
    property ButtonShape: TSimButtonShape read FShape write SetShape default sbsRound;

    property Align;
    property Anchors;
    property Visible;
    property Enabled;
    property Font;
    property Width default 60;
    property Height default 60;
    property OnClick;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseEnter;
    property OnMouseLeave;
  end;

implementation

{ ==============================================================================
  TSimPushButton
  ============================================================================== }

constructor TSimPushButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 60;
  Height := 60;
  FButtonColor := clMaroon;
  FShape := sbsRound;
  FPressed := False;
  FHovered := False;
  FCaption := 'PUSH';

  Font.Name := 'Arial';
  Font.Style := [fsBold];
  Font.Color := clWhite;
  Font.Size := 8;
end;

procedure TSimPushButton.SetCaption(const AValue: String);
begin
  if FCaption = AValue then Exit;
  FCaption := AValue;
  Invalidate;
end;

procedure TSimPushButton.SetButtonColor(AValue: TColor);
begin
  if FButtonColor = AValue then Exit;
  FButtonColor := AValue;
  Invalidate;
end;

procedure TSimPushButton.SetShape(AValue: TSimButtonShape);
begin
  if FShape = AValue then Exit;
  FShape := AValue;
  InvalidateBackground; // Bentuk bezel berubah, perlu redraw background
end;

procedure TSimPushButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FPressed := True;
    Invalidate; // Redraw state ditekan
  end;
end;

procedure TSimPushButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if (Button = mbLeft) and FPressed then
  begin
    FPressed := False;
    Invalidate; // Redraw state dilepas

    // Picu event OnClick jika kursor masih berada di dalam area kontrol
    if (X >= 0) and (X <= Width) and (Y >= 0) and (Y <= Height) then
      if Assigned(OnClick) then OnClick(Self);
  end;
end;

procedure TSimPushButton.MouseEnter;
begin
  inherited MouseEnter;
  if Enabled then
  begin
    FHovered := True;
    Invalidate;
  end;
end;

procedure TSimPushButton.MouseLeave;
begin
  inherited MouseLeave;
  if Enabled then
  begin
    FHovered := False;
    FPressed := False; // Batal tekan jika kursor keluar area
    Invalidate;
  end;
end;

procedure TSimPushButton.DrawBackground(ABitmap: TBGRABitmap);
var
  CX, CY, Radius: Single;
  BaseRect: TRectF;
  GradScanner: IBGRAScanner;
begin
  inherited DrawBackground(ABitmap);

  CX := Width / 2;
  CY := Height / 2;

  // 1. Gambar Bezel/Casing Logam Luar (Statis)
  if FShape = sbsRound then
  begin
    Radius := Min(CX, CY) - 2;

    // Outer Shadow
    ABitmap.FillEllipseAntialias(CX, CY + 2, Radius, Radius, BGRA(0, 0, 0, 100));

    // Metallic Ring Bezel
    GradScanner := TBGRAGradientScanner.Create(
      BGRA(230, 230, 230, 255), BGRA(80, 80, 80, 255),
      gtLinear, PointF(CX - Radius, CY - Radius), PointF(CX + Radius, CY + Radius));
    ABitmap.FillEllipseAntialias(CX, CY, Radius, Radius, GradScanner);

    // Inner Shadow (Lubang dudukan tombol)
    ABitmap.EllipseAntialias(CX, CY, Radius * 0.85, Radius * 0.85, BGRA(0, 0, 0, 200), 2.0);
    ABitmap.FillEllipseAntialias(CX, CY, Radius * 0.85, Radius * 0.85, BGRA(20, 20, 20, 255));
  end
  else // sbsRectangular
  begin
    BaseRect := RectF(2, 2, Width - 2, Height - 2);

    // Outer Shadow
    ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top + 2, BaseRect.Right, BaseRect.Bottom + 2, 4, 4, BGRA(0, 0, 0, 100));

    // Metallic Panel Bezel
    GradScanner := TBGRAGradientScanner.Create(
      BGRA(230, 230, 230, 255), BGRA(80, 80, 80, 255),
      gtLinear, PointF(BaseRect.Left, BaseRect.Top), PointF(BaseRect.Right, BaseRect.Bottom));
    ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 4, 4, GradScanner);

    // Inner Shadow (Lubang dudukan tombol)
    BaseRect := RectF(8, 8, Width - 8, Height - 8);
    ABitmap.RoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 2, 2, BGRA(0, 0, 0, 200), 2.0);
    ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 2, 2, BGRA(20, 20, 20, 255));
  end;
end;

procedure TSimPushButton.DrawForeground(ABitmap: TBGRABitmap);
var
  CX, CY, Radius: Single;
  FaceRect: TRectF;
  C: TBGRAPixel;
  R, G, B: Byte;
  GradScanner: IBGRAScanner;
  Offset: Single;
  TextX, TextY: Single;
begin
  inherited DrawForeground(ABitmap);

  CX := Width / 2;
  CY := Height / 2;

  // Ambil warna dasar
  C := ColorToBGRA(ColorToRGB(FButtonColor));
  R := C.red;
  G := C.green;
  B := C.blue;

  // Efek Hover: Terangkan sedikit warnanya
  if FHovered and not FPressed then
  begin
    R := Min(255, R + 30);
    G := Min(255, G + 30);
    B := Min(255, B + 30);
  end;

  // Offset pergerakan tombol saat ditekan (Tenggelam ke dalam)
  if FPressed then Offset := 2.0 else Offset := -2.0;

  if FShape = sbsRound then
  begin
    Radius := Min(CX, CY) * 0.8; // Ukuran tombol sedikit lebih kecil dari lubang

    // Jika tidak ditekan, gambar bayangan body tombol
    if not FPressed then
      ABitmap.FillEllipseAntialias(CX, CY, Radius, Radius, BGRA(Max(0, R-80), Max(0, G-80), Max(0, B-80), 255));

    // Wajah tombol (Bergeser berdasarkan state ditekan)
    GradScanner := TBGRAGradientScanner.Create(
      BGRA(Min(255, R+50), Min(255, G+50), Min(255, B+50), 255),
      BGRA(Max(0, R-50), Max(0, G-50), Max(0, B-50), 255),
      gtLinear, PointF(CX - Radius, CY - Radius + Offset), PointF(CX + Radius, CY + Radius + Offset));

    ABitmap.FillEllipseAntialias(CX, CY + Offset, Radius, Radius, GradScanner);

    // Highlight pantulan cahaya atas (Gloss)
    if not FPressed then
      ABitmap.FillEllipseAntialias(CX, CY + Offset - Radius*0.5, Radius*0.6, Radius*0.3, BGRA(255, 255, 255, 60));

  end
  else // sbsRectangular
  begin
    FaceRect := RectF(10, 10, Width - 10, Height - 10);

    // Bayangan body tombol
    if not FPressed then
      ABitmap.FillRoundRectAntialias(FaceRect.Left, FaceRect.Top, FaceRect.Right, FaceRect.Bottom, 2, 2, BGRA(Max(0, R-80), Max(0, G-80), Max(0, B-80), 255));

    // Wajah tombol
    GradScanner := TBGRAGradientScanner.Create(
      BGRA(Min(255, R+50), Min(255, G+50), Min(255, B+50), 255),
      BGRA(Max(0, R-50), Max(0, G-50), Max(0, B-50), 255),
      gtLinear, PointF(FaceRect.Left, FaceRect.Top + Offset), PointF(FaceRect.Right, FaceRect.Bottom + Offset));

    ABitmap.FillRoundRectAntialias(FaceRect.Left, FaceRect.Top + Offset, FaceRect.Right, FaceRect.Bottom + Offset, 2, 2, GradScanner);

    // Highlight pantulan cahaya atas
    if not FPressed then
      ABitmap.FillRoundRectAntialias(FaceRect.Left + 2, FaceRect.Top + Offset + 2, FaceRect.Right - 2, FaceRect.Top + Offset + (FaceRect.Bottom - FaceRect.Top)*0.3, 2, 2, BGRA(255, 255, 255, 60));
  end;

  // Render Teks (Caption) di tengah tombol
  if FCaption <> '' then
  begin
    ABitmap.FontName := Font.Name;
    if Abs(Font.Height) > 0 then ABitmap.FontHeight := Abs(Font.Height) else ABitmap.FontHeight := 10;
    ABitmap.FontStyle := Font.Style;
    ABitmap.FontAntialias := True;

    TextX := CX - (ABitmap.TextSize(FCaption).cx / 2);
    TextY := CY - (ABitmap.TextSize(FCaption).cy / 2) + Offset;

    // Drop shadow pada teks agar terlihat menyatu
    ABitmap.TextOut(TextX, TextY + 1, FCaption, BGRA(0, 0, 0, 150));
    ABitmap.TextOut(TextX, TextY, FCaption, ColorToBGRA(ColorToRGB(Font.Color)));
  end;
end;

end.
