{ ==============================================================================
  File: SimFader.pas
  Deskripsi: Komponen Fader/Slider linier (Vertical/Horizontal) dengan
             desain skeuomorphic gaya mixer audio/konsol industri.
  ============================================================================== }

unit SimFader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Math, Types,
  SimBase, SimUtils, BGRABitmap, BGRABitmapTypes, BGRAGradientScanner;

type
  TSimFaderOrientation = (foVertical, foHorizontal);

  { TSimFader }
  TSimFader = class(TSimCustomControl)
  private
    FValue: Extended;
    FMin: Extended;
    FMax: Extended;
    FOrientation: TSimFaderOrientation;
    FOnChange: TNotifyEvent;

    FIsDragging: Boolean;
    FThumbRect: TRectF; // Menyimpan area thumb untuk deteksi mouse

    procedure SetValue(AValue: Extended);
    procedure SetMin(AValue: Extended);
    procedure SetMax(AValue: Extended);
    procedure SetOrientation(AValue: TSimFaderOrientation);
    procedure UpdateValueFromMouse(X, Y: Integer);
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    procedure DrawBackground(ABitmap: TBGRABitmap); override;
    procedure DrawForeground(ABitmap: TBGRABitmap); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Value: Extended read FValue write SetValue;
    property Min: Extended read FMin write SetMin;
    property Max: Extended read FMax write SetMax;
    property Orientation: TSimFaderOrientation read FOrientation write SetOrientation default foVertical;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    property Align;
    property Anchors;
    property Visible;
    property Enabled;
    property Width default 60;
    property Height default 200;
  end;

implementation

{ ==============================================================================
  TSimFader
  ============================================================================== }

constructor TSimFader.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 60;
  Height := 200;
  FMin := 0;
  FMax := 100;
  FValue := 0;
  FOrientation := foVertical;
  FIsDragging := False;
end;

procedure TSimFader.SetValue(AValue: Extended);
var
  NewVal: Extended;
begin
  NewVal := EnsureRange(AValue, FMin, FMax);
  if FValue = NewVal then Exit;
  FValue := NewVal;
  Invalidate; // Hanya memicu DrawForeground (Thumb bergerak)
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TSimFader.SetMin(AValue: Extended);
begin
  if FMin = AValue then Exit;
  FMin := AValue;
  if FValue < FMin then SetValue(FMin);
  InvalidateBackground; // Skala berubah, gambar ulang latar
end;

procedure TSimFader.SetMax(AValue: Extended);
begin
  if FMax = AValue then Exit;
  FMax := AValue;
  if FValue > FMax then SetValue(FMax);
  InvalidateBackground;
end;

procedure TSimFader.SetOrientation(AValue: TSimFaderOrientation);
var
  Temp: Integer;
begin
  if FOrientation = AValue then Exit;
  FOrientation := AValue;

  // Tukar dimensi jika orientasi berubah (opsional, untuk kemudahan desain)
  if not (csLoading in ComponentState) then
  begin
    Temp := Width;
    Width := Height;
    Height := Temp;
  end;

  InvalidateBackground;
end;

procedure TSimFader.UpdateValueFromMouse(X, Y: Integer);
var
  NewVal: Extended;
  Pad: Single;
begin
  Pad := 25; // Margin ujung track
  if FOrientation = foVertical then
    // Pada fader vertikal, Y tertinggi ada di bawah (Min) dan Y terendah di atas (Max)
    NewVal := SimMapValue(Y, Height - Pad, Pad, FMin, FMax)
  else
    // Pada fader horizontal, X terendah di kiri (Min) dan X tertinggi di kanan (Max)
    NewVal := SimMapValue(X, Pad, Width - Pad, FMin, FMax);

  SetValue(NewVal);
end;

procedure TSimFader.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FIsDragging := True;
    UpdateValueFromMouse(X, Y); // Langsung lompat ke posisi klik
  end;
end;

procedure TSimFader.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FIsDragging and Enabled then
  begin
    UpdateValueFromMouse(X, Y);
  end;
end;

procedure TSimFader.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then FIsDragging := False;
end;

procedure TSimFader.DrawBackground(ABitmap: TBGRABitmap);
var
  BaseRect, TrackRect: TRectF;
  GradScanner: IBGRAScanner;
  Pad, TickPos: Single;
  i: Integer;
begin
  inherited DrawBackground(ABitmap);

  Pad := 25; // Margin padding atas-bawah atau kiri-kanan
  BaseRect := RectF(2, 2, Width - 2, Height - 2);

  // 1. Plat Besi Utama Latar Belakang (Bezel luar)
  GradScanner := TBGRAGradientScanner.Create(
    BGRA(210, 210, 210, 255), BGRA(130, 130, 130, 255),
    gtLinear, PointF(BaseRect.Left, BaseRect.Top), PointF(BaseRect.Right, BaseRect.Bottom));
  ABitmap.FillRoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 3, 3, GradScanner);
  ABitmap.RoundRectAntialias(BaseRect.Left, BaseRect.Top, BaseRect.Right, BaseRect.Bottom, 3, 3, BGRA(80, 80, 80, 255), 1.5);

  // 2. Garis Slot (Lubang Track)
  if FOrientation = foVertical then
    TrackRect := RectF(Width / 2 - 4, Pad, Width / 2 + 4, Height - Pad)
  else
    TrackRect := RectF(Pad, Height / 2 - 4, Width - Pad, Height / 2 + 4);

  // Isi Slot (Gelap)
  ABitmap.FillRectAntialias(TrackRect.Left, TrackRect.Top, TrackRect.Right, TrackRect.Bottom, BGRA(20, 20, 20, 255));

  // Efek Bayangan Dalam Slot (Inner Shadow)
  ABitmap.DrawLineAntialias(TrackRect.Left, TrackRect.Top, TrackRect.Right, TrackRect.Top, BGRA(0, 0, 0, 200), 2);
  ABitmap.DrawLineAntialias(TrackRect.Left, TrackRect.Top, TrackRect.Left, TrackRect.Bottom, BGRA(0, 0, 0, 200), 2);
  ABitmap.DrawLineAntialias(TrackRect.Right, TrackRect.Bottom, TrackRect.Right, TrackRect.Top, BGRA(255, 255, 255, 50), 1); // Highlight sisi bawah

  // 3. Ticks / Skala Pengukuran
  for i := 0 to 10 do
  begin
    if FOrientation = foVertical then
    begin
      // Titik 0 di bawah, 10 di atas
      TickPos := (Height - Pad) - (i * ((Height - Pad * 2) / 10));
      // Tick Kanan
      ABitmap.DrawLineAntialias(TrackRect.Right + 5, TickPos, TrackRect.Right + 12, TickPos, BGRA(30, 30, 30, 255), 1.5);
      // Tick Kiri (Lebih kecil)
      ABitmap.DrawLineAntialias(TrackRect.Left - 12, TickPos, TrackRect.Left - 5, TickPos, BGRA(30, 30, 30, 255), 1.0);
    end
    else
    begin
      // Titik 0 di kiri, 10 di kanan
      TickPos := Pad + (i * ((Width - Pad * 2) / 10));
      // Tick Bawah
      ABitmap.DrawLineAntialias(TickPos, TrackRect.Bottom + 5, TickPos, TrackRect.Bottom + 12, BGRA(30, 30, 30, 255), 1.5);
      // Tick Atas (Lebih kecil)
      ABitmap.DrawLineAntialias(TickPos, TrackRect.Top - 12, TickPos, TrackRect.Top - 5, BGRA(30, 30, 30, 255), 1.0);
    end;
  end;

  // Detail Sekrup Penahan di ujung fader
  if FOrientation = foVertical then
  begin
    ABitmap.FillEllipseAntialias(Width / 2, Pad / 2, 3, 3, BGRA(40, 40, 40, 255));
    ABitmap.FillEllipseAntialias(Width / 2, Height - Pad / 2, 3, 3, BGRA(40, 40, 40, 255));
  end
  else
  begin
    ABitmap.FillEllipseAntialias(Pad / 2, Height / 2, 3, 3, BGRA(40, 40, 40, 255));
    ABitmap.FillEllipseAntialias(Width - Pad / 2, Height / 2, 3, 3, BGRA(40, 40, 40, 255));
  end;
end;

procedure TSimFader.DrawForeground(ABitmap: TBGRABitmap);
var
  Pad, PosCenter, ThumbW, ThumbH, GripPos: Single;
  GradScanner: IBGRAScanner;
  i: Integer;
begin
  inherited DrawForeground(ABitmap);

  Pad := 25;

  // 1. Hitung Dimensi & Posisi Thumb
  if FOrientation = foVertical then
  begin
    PosCenter := SimMapValue(FValue, FMin, FMax, Height - Pad, Pad);
    ThumbW := Math.Min(Width * 0.7, 40.0);
    ThumbH := 24.0;
    FThumbRect := RectF(Width/2 - ThumbW/2, PosCenter - ThumbH/2, Width/2 + ThumbW/2, PosCenter + ThumbH/2);
  end
  else
  begin
    PosCenter := SimMapValue(FValue, FMin, FMax, Pad, Width - Pad);
    ThumbW := 24.0;
    ThumbH := Math.Min(Height * 0.7, 40.0);
    FThumbRect := RectF(PosCenter - ThumbW/2, Height/2 - ThumbH/2, PosCenter + ThumbW/2, Height/2 + ThumbH/2);
  end;

  // 2. Bayangan Jatuh Thumb (Drop Shadow)
  ABitmap.FillRoundRectAntialias(FThumbRect.Left + 4, FThumbRect.Top + 6, FThumbRect.Right + 4, FThumbRect.Bottom + 6, 4, 4, BGRA(0, 0, 0, 120));

  // 3. Render Badan Thumb (Bentuk Knob Plastik / Metalik)
  if FOrientation = foVertical then
    GradScanner := TBGRAGradientScanner.Create(
      BGRA(230, 230, 230, 255), BGRA(60, 60, 60, 255),
      gtLinear, PointF(FThumbRect.Left, FThumbRect.Top), PointF(FThumbRect.Right, FThumbRect.Top))
  else
    GradScanner := TBGRAGradientScanner.Create(
      BGRA(230, 230, 230, 255), BGRA(60, 60, 60, 255),
      gtLinear, PointF(FThumbRect.Left, FThumbRect.Top), PointF(FThumbRect.Left, FThumbRect.Bottom));

  ABitmap.FillRoundRectAntialias(FThumbRect.Left, FThumbRect.Top, FThumbRect.Right, FThumbRect.Bottom, 3, 3, GradScanner);
  ABitmap.RoundRectAntialias(FThumbRect.Left, FThumbRect.Top, FThumbRect.Right, FThumbRect.Bottom, 3, 3, BGRA(40, 40, 40, 255), 1);

  // 4. Grip Lines (Garis Timbul Tengah agar tidak licin)
  if FOrientation = foVertical then
  begin
    // Garis Penanda Nilai (Putih di tengah)
    ABitmap.DrawLineAntialias(FThumbRect.Left, PosCenter, FThumbRect.Right, PosCenter, BGRA(255, 255, 255, 255), 2.0);
    // Garis cengkeraman (Grips)
    for i := 1 to 2 do
    begin
      GripPos := PosCenter - (i * 4);
      ABitmap.DrawLineAntialias(FThumbRect.Left + 5, GripPos, FThumbRect.Right - 5, GripPos, BGRA(30, 30, 30, 200), 1.0);
      GripPos := PosCenter + (i * 4);
      ABitmap.DrawLineAntialias(FThumbRect.Left + 5, GripPos, FThumbRect.Right - 5, GripPos, BGRA(30, 30, 30, 200), 1.0);
    end;
  end
  else
  begin
    // Garis Penanda Nilai (Putih di tengah)
    ABitmap.DrawLineAntialias(PosCenter, FThumbRect.Top, PosCenter, FThumbRect.Bottom, BGRA(255, 255, 255, 255), 2.0);
    // Garis cengkeraman (Grips)
    for i := 1 to 2 do
    begin
      GripPos := PosCenter - (i * 4);
      ABitmap.DrawLineAntialias(GripPos, FThumbRect.Top + 5, GripPos, FThumbRect.Bottom - 5, BGRA(30, 30, 30, 200), 1.0);
      GripPos := PosCenter + (i * 4);
      ABitmap.DrawLineAntialias(GripPos, FThumbRect.Top + 5, GripPos, FThumbRect.Bottom - 5, BGRA(30, 30, 30, 200), 1.0);
    end;
  end;
end;

end.
