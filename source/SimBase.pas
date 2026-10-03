unit SimBase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, BGRABitmap, BGRABitmapTypes;

type

  { TSimGraphicControl }
  { Base class untuk komponen output (Gauge, LED) yang tidak menerima input/fokus }
  TSimGraphicControl = class(TGraphicControl)
  private
    FBackgroundBitmap: TBGRABitmap;
    FBufferBitmap: TBGRABitmap;
    FBgNeedsUpdate: Boolean;
    procedure FreeBitmaps;
  protected
    procedure Resize; override;
    procedure Paint; override;

    { Method virtual yang harus di-override oleh kelas turunan }
    { DrawBackground dipanggil hanya ketika ukuran/properti statis berubah }
    procedure DrawBackground(ABitmap: TBGRABitmap); virtual;
    { DrawForeground dipanggil setiap kali komponen dirender ulang (real-time) }
    procedure DrawForeground(ABitmap: TBGRABitmap); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Panggil method ini jika properti visual statis (warna, bingkai) berubah }
    procedure InvalidateBackground;
  end;

  { TSimCustomControl }
  { Base class untuk komponen interaktif (Knob, Switch) yang merespons mouse/keyboard }
  TSimCustomControl = class(TCustomControl)
  private
    FBackgroundBitmap: TBGRABitmap;
    FBufferBitmap: TBGRABitmap;
    FBgNeedsUpdate: Boolean;
    procedure FreeBitmaps;
  protected
    procedure Resize; override;
    procedure Paint; override;

    procedure DrawBackground(ABitmap: TBGRABitmap); virtual;
    procedure DrawForeground(ABitmap: TBGRABitmap); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure InvalidateBackground;
  end;

implementation

{ TSimGraphicControl }

constructor TSimGraphicControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  { csOpaque mencegah LCL menggambar background bawaan yang menyebabkan flickering }
  ControlStyle := ControlStyle + [csOpaque];
  FBgNeedsUpdate := True;
  FBackgroundBitmap := nil;
  FBufferBitmap := nil;
end;

destructor TSimGraphicControl.Destroy;
begin
  FreeBitmaps;
  inherited Destroy;
end;

procedure TSimGraphicControl.FreeBitmaps;
begin
  if Assigned(FBackgroundBitmap) then FreeAndNil(FBackgroundBitmap);
  if Assigned(FBufferBitmap) then FreeAndNil(FBufferBitmap);
end;

procedure TSimGraphicControl.Resize;
begin
  inherited Resize;
  FBgNeedsUpdate := True; // Ukuran berubah, background statis harus digambar ulang
  Invalidate; // Memicu event Paint
end;

procedure TSimGraphicControl.InvalidateBackground;
begin
  FBgNeedsUpdate := True;
  Invalidate;
end;

procedure TSimGraphicControl.DrawBackground(ABitmap: TBGRABitmap);
begin
  // Default: Kosongkan dengan warna transparan (akan ditimpa oleh turunan)
  ABitmap.FillTransparent;
end;

procedure TSimGraphicControl.DrawForeground(ABitmap: TBGRABitmap);
begin
  // Kosong (akan ditimpa oleh turunan untuk menggambar elemen dinamis seperti jarum)
end;

procedure TSimGraphicControl.Paint;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  // Inisialisasi/Alokasi ulang memori bitmap jika belum ada atau ukuran komponen berubah
  if (not Assigned(FBackgroundBitmap)) or (FBackgroundBitmap.Width <> Width) or (FBackgroundBitmap.Height <> Height) then
  begin
    FreeBitmaps;
    FBackgroundBitmap := TBGRABitmap.Create(Width, Height);
    FBufferBitmap := TBGRABitmap.Create(Width, Height);
    FBgNeedsUpdate := True;
  end;

  // 1. CACHING: Gambar layer statis hanya jika ada perubahan struktur (sangat menghemat CPU)
  if FBgNeedsUpdate then
  begin
    DrawBackground(FBackgroundBitmap);
    FBgNeedsUpdate := False;
  end;

  // 2. BUFFERING: Salin background statis ke buffer kerja
  FBufferBitmap.PutImage(0, 0, FBackgroundBitmap, dmSet);

  // 3. RENDER DINAMIS: Gambar elemen bergerak (jarum, lampu) di atas buffer
  DrawForeground(FBufferBitmap);

  // 4. TAMPILKAN: Salin hasil akhir buffer ke Canvas layar LCL (Double Buffering)
  FBufferBitmap.Draw(Canvas, 0, 0, False);
end;


{ TSimCustomControl }

constructor TSimCustomControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  { Tambahkan flag kontrol interaktif, klik, dan perlakuan khusus LCL }
  ControlStyle := ControlStyle + [csOpaque, csAcceptsControls, csCaptureMouse, csClickEvents, csDoubleClicks];
  DoubleBuffered := True; // Fitur bawaan LCL untuk mengurangi flicker pada TCustomControl
  FBgNeedsUpdate := True;
  FBackgroundBitmap := nil;
  FBufferBitmap := nil;
end;

destructor TSimCustomControl.Destroy;
begin
  FreeBitmaps;
  inherited Destroy;
end;

procedure TSimCustomControl.FreeBitmaps;
begin
  if Assigned(FBackgroundBitmap) then FreeAndNil(FBackgroundBitmap);
  if Assigned(FBufferBitmap) then FreeAndNil(FBufferBitmap);
end;

procedure TSimCustomControl.Resize;
begin
  inherited Resize;
  FBgNeedsUpdate := True;
  Invalidate;
end;

procedure TSimCustomControl.InvalidateBackground;
begin
  FBgNeedsUpdate := True;
  Invalidate;
end;

procedure TSimCustomControl.DrawBackground(ABitmap: TBGRABitmap);
begin
  ABitmap.FillTransparent;
end;

procedure TSimCustomControl.DrawForeground(ABitmap: TBGRABitmap);
begin
end;

procedure TSimCustomControl.Paint;
begin
  if (Width <= 0) or (Height <= 0) then Exit;

  if (not Assigned(FBackgroundBitmap)) or (FBackgroundBitmap.Width <> Width) or (FBackgroundBitmap.Height <> Height) then
  begin
    FreeBitmaps;
    FBackgroundBitmap := TBGRABitmap.Create(Width, Height);
    FBufferBitmap := TBGRABitmap.Create(Width, Height);
    FBgNeedsUpdate := True;
  end;

  if FBgNeedsUpdate then
  begin
    DrawBackground(FBackgroundBitmap);
    FBgNeedsUpdate := False;
  end;

  FBufferBitmap.PutImage(0, 0, FBackgroundBitmap, dmSet);
  DrawForeground(FBufferBitmap);
  FBufferBitmap.Draw(Canvas, 0, 0, False);
end;

end.

