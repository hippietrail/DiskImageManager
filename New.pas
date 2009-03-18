unit New;

{
  Disk Image Manager -  Copyright 2002-2009 Envy Technologies Ltd.

  New Disk window
}

interface

uses
  DskImage, Main,
  Windows, Messages, SysUtils, Variants, Classes, Controls, Forms,
  StdCtrls, ComCtrls, ExtCtrls, Dialogs, Buttons;

type
  TfrmNew = class(TForm)
    pnlInfo: TPanel;
    pnlTabs: TPanel;
    pnlButtons: TPanel;
    btnFormat: TButton;
    btnCancel: TButton;
    pagTabs: TPageControl;
    tabFormat: TTabSheet;
    tabDetails: TTabSheet;
    tabDiskSpec: TTabSheet;
    lblSides: TLabel;
    cboSides: TComboBox;
    lblTracks: TLabel;
    edtTracks: TEdit;
    lblSectors: TLabel;
    edtSectors: TEdit;
    lblSecSize: TLabel;
    edtSecSize: TEdit;
    udSecSize: TUpDown;
    lblGapRW: TLabel;
    edtGapRW: TEdit;
    udGapRW: TUpDown;
    lblGapFormat: TLabel;
    edtGapFormat: TEdit;
    udGapFormat: TUpDown;
    lblResTracks: TLabel;
    edtResTracks: TEdit;
    udResTracks: TUpDown;
    lblDirBlocks: TLabel;
    edtDirBlocks: TEdit;
    udDirBlocks: TUpDown;
    lblFiller: TLabel;
    edtFiller: TEdit;
    udFiller: TUpDown;
    lblFillHex: TLabel;
    udTracks: TUpDown;
    udSectors: TUpDown;
    chkWriteDiskSpec: TCheckBox;
    lblFormatDesc: TLabel;
    lvwFormats: TListView;
    lblSpecDesc: TLabel;
    lvwWarnings: TListView;
    pnlSummary: TPanel;
    lvwSummary: TListView;
    pnlWarnings: TPanel;
    chkAdjust: TCheckBox;
    lblFirstSector: TLabel;
    edtFirstSector: TEdit;
    udFirstSector: TUpDown;
    lblInterleave: TLabel;
    edtInterleave: TEdit;
    udInterleave: TUpDown;
    lblSkewTrack: TLabel;
    edtSkewTrack: TEdit;
    udSkewTrack: TUpDown;
    dlgOpenBoot: TOpenDialog;
    lblBlockSize: TLabel;
    edtBlockSize: TEdit;
    udBlockSize: TUpDown;
    lblSkewSide: TLabel;
    edtSkewSide: TEdit;
    udSkewSide: TUpDown;
    tabBoot: TTabSheet;
    lblBootDesc: TLabel;
    lblBootBinary: TLabel;
    lblBootType: TLabel;
    cboBootMachine: TComboBox;
    lblBinFile: TLabel;
    lblBinOffset: TLabel;
    lvwBootDetails: TListView;
    lblBootDetails: TLabel;
    btnBootClear: TBitBtn;
    btnBootBin: TBitBtn;
    procedure edtFillerChange(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnFormatClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lvwFormatsChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure cboSidesChange(Sender: TObject);
    procedure edtTracksChange(Sender: TObject);
    procedure edtSectorsChange(Sender: TObject);
    procedure edtSecSizeChange(Sender: TObject);
    procedure edtGapRWChange(Sender: TObject);
    procedure edtGapFormatChange(Sender: TObject);
    procedure edtResTracksChange(Sender: TObject);
    procedure edtDirBlocksChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure chkWriteDiskSpecClick(Sender: TObject);
    procedure chkAdjustClick(Sender: TObject);
    procedure edtSkewTrackChange(Sender: TObject);
    procedure edtInterleaveChange(Sender: TObject);
    procedure edtFirstSectorChange(Sender: TObject);
    procedure cboBootMachineChange(Sender: TObject);
    procedure btnBootBinClick(Sender: TObject);
    procedure edtSkewSideChange(Sender: TObject);
    procedure tabBootShow(Sender: TObject);
    procedure btnBootClearClick(Sender: TObject);
    procedure edtBlockSizeChange(Sender: TObject);
  private
    CurrentFormat: TDSKFormatSpecification;

    BootSectorBin: array[0..MaxSectorSize] of Byte;
    BootOffset, BootSectorSize: Word;
    BootChecksum: Byte;
    BootChecksumRequired: Boolean;
    procedure SetShowAdvanced(ShowAdvanced: Boolean);
	  procedure SetCurrentFormat(ItemIndex: Integer);
    procedure UpdateDetails;
    procedure UpdateSummary;
    procedure UpdateFileDetails;
    function IsPlus3Format: Boolean;
  end;

var
  frmNew: TfrmNew;

implementation

{$R *.dfm}

procedure TfrmNew.edtFillerChange(Sender: TObject);
begin
	lblFillHex.Caption := Format('%.2x',[udFiller.Position]);
end;

procedure TfrmNew.btnCancelClick(Sender: TObject);
begin
	Close;
end;

procedure TfrmNew.UpdateDetails;
begin
	with CurrentFormat do
  begin
	  cboSides.ItemIndex := Ord(Sides);
    udTracks.Position := TracksPerSide;
    udSectors.Position := SectorsPerTrack;
    udSecSize.Position := SectorSize;
    udFirstSector.Position := FirstSector;
    udGapRW.Position := GapRW;
    udGapFormat.Position := GapFormat;
    udResTracks.Position := ResTracks;
    udDirBlocks.Position := DirBlocks;
    udBlockSize.Position := BlockSize;
    udFiller.Position := FillerByte;
    udInterleave.Position := Interleave;
    udSkewTrack.Position := SkewTrack;
    udSkewSide.Position := SkewSide;
  end;
	UpdateSummary;
end;

procedure TfrmNew.UpdateSummary;
var
	NewWarn: TListItem;
begin
	// Set summary details
	if lvwSummary.Items.Count > 0 then
  begin
		lvwSummary.Items[0].SubItems[0] :=
	 		Format('%d KB',[CurrentFormat.GetCapacityBytes div 1024]);
		lvwSummary.Items[1].SubItems[0] :=
	 		Format('%d KB',[CurrentFormat.GetUsableBytes div 1024]);
     lvwSummary.Items[2].SubItems[0] :=
     	Format('%d',[CurrentFormat.GetDirectoryEntries]);
     if CurrentFormat.ResTracks > 0 then
     	lvwsummary.Items[3].SubItems[0] := 'Yes'
     else
     	lvwsummary.Items[3].SubItems[0] := 'No';
  end;

  lvwWarnings.Items.Clear;

  // Boot warnings
  if (BootSectorSize > 0) then
  begin
  	if (cboBootMachine.ItemIndex = 3) then
     begin
     	if (CurrentFormat.FirstSector <> 65) then
  		begin
    	  	  NewWarn := lvwWarnings.Items.Add;
          NewWarn.Caption := 'Boot on CPC requires first sector ID of 65';
  		end;

  		if (chkWriteDiskSpec.Checked) then
  		begin
          NewWarn := lvwWarnings.Items.Add;
          NewWarn.Caption := 'CPC boot sector overwrites disk specification';
		   end;
     end;

  	if (CurrentFormat.ResTracks < 1) then
  	begin
   	  NewWarn := lvwWarnings.Items.Add;
    	  NewWarn.Caption := 'Boot requires a reserved track';
  	end;

  	if (cboBootMachine.ItemIndex < 3) and (not chkWriteDiskSpec.Checked) then
  	begin
       NewWarn := lvwWarnings.Items.Add;
    	  NewWarn.Caption := 'Boot on PCW/+3 requires a disk specification';
  	end;
  end;

  // Set any warnings
  if (not IsPlus3Format) and (not chkWriteDiskSpec.Checked) then
  begin
  	NewWarn := lvwWarnings.Items.Add;
     NewWarn.Caption := 'Format requires disk specification on PCW/+3';
  end;

  if (CurrentFormat.DirBlocks = 0) then
  begin
  	NewWarn := lvwWarnings.Items.Add;
     NewWarn.Caption := 'File system has no directory blocks';
  end;

  if (CurrentFormat.ResTracks = 0) and (chkWriteDiskSpec.Checked) then
  begin
  	NewWarn := lvwWarnings.Items.Add;
     NewWarn.Caption := 'Disk spec should use a reserved track';
  end;

  if (CurrentFormat.SectorSize > 512) then
  begin
  	NewWarn := lvwWarnings.Items.Add;
     NewWarn.Caption := '512 bytes per sector limit in +3DOS';
  end;

  if (CurrentFormat.Interleave = 0) then
  begin
  	NewWarn := lvwWarnings.Items.Add;
     NewWarn.Caption := 'Interleave can not be 0';
  end;

  if (CurrentFormat.SectorSize * CurrentFormat.SectorsPerTrack > 6144) then
  begin
  	NewWarn := lvwWarnings.Items.Add;
     NewWarn.Caption := '6144 bytes per track limit on +3';
  end;

  if (lvwFormats.Selected <> nil) and (chkWriteDiskSpec.Checked) then
  	with lvwFormats.Selected do
  	if (ImageIndex=2) or (ImageIndex=3) or (ImageIndex=7) then
     	begin
          NewWarn := lvwWarnings.Items.Add;
          NewWarn.Caption := 'Disk specification unsupported by Amstrad CPC';
        end;
end;

procedure TfrmNew.btnFormatClick(Sender: TObject);
var
	NewImage: TDSKImage;
  CopySize: Integer;
begin
	NewImage := TDSKImage.Create;
  with NewImage do
  begin
		FileName := Format('Untitled %d.dsk',[frmMain.GetNextNewFile]);
	   FileFormat := diNotYetSaved;
  	Disk.Format(CurrentFormat);
  end;

  if chkWriteDiskSpec.Checked then
		with NewImage.Disk.Specification do
    	begin
       Format := dsFormatPCW_SS;
       if (lvwFormats.Selected.ImageIndex = 2) then Format := dsFormatCPC_System;
       if (lvwFormats.Selected.ImageIndex = 3) then Format := dsFormatCPC_Data;
       if (CurrentFormat.Sides <> dsSideSingle) then Format := dsFormatPCW_DS;

       Side := CurrentFormat.Sides;
       BlockSize := CurrentFormat.BlockSize;
       DirectoryBlocks := CurrentFormat.DirBlocks;
       GapFormat := CurrentFormat.GapFormat;
       GapReadWrite := CurrentFormat.GapRW;
       ReservedTracks := CurrentFormat.ResTracks;
       SectorsPerTrack := CurrentFormat.SectorsPerTrack;
       FDCSectorSize := CurrentFormat.FDCSectorSize;
       SectorSize := CurrentFormat.SectorSize;
       TracksPerSide := CurrentFormat.TracksPerSide;
       Checksum := 0;

       if (TracksPerSide > 50) then
          Track := dsTrackDouble
       else
          Track := dsTrackSingle;
       Write;
   	end;

	if (BootSectorSize > 0) then
  	with NewImage.Disk.Side[0].Track[0].Sector[0] do
  	begin
       CopySize := (CurrentFormat.SectorSize - BootOffset);
    	  if BootSectorSize < CopySize then CopySize := BootSectorSize;
	     Move(BootSectorBin,Data[BootOffset],CopySize);
       if (chkWriteDiskSpec.Checked) and (BootChecksumRequired) then
       begin
         NewImage.Disk.Specification.Checksum := (255 - GetModChecksum(256) + BootChecksum + 1) Mod 256;
			 NewImage.Disk.Specification.Write;
       end;
     end;

  frmMain.AddWorkspaceImage(NewImage);
end;

procedure TfrmNew.FormCreate(Sender: TObject);
var
	Idx: Integer;
begin
	CurrentFormat := TDSKFormatSpecification.Create;
	for Idx := 0 to Length(DSKSpecSides)-2 do
		cboSides.Items.Add(DSKSpecSides[TDSKSpecSide(Idx)]);

  BootOffset := 0;
	BootChecksumRequired := False;
  pagTabs.ActivePage := tabFormat;
	SetShowAdvanced(False);
end;

procedure TfrmNew.lvwFormatsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
	if (lvwFormats.Selected <> nil) then
  	SetCurrentFormat(lvwFormats.Selected.ImageIndex);
end;

procedure TfrmNew.SetCurrentFormat(ItemIndex: Integer);
begin

	// Amstrad PCW/Spectrum +3 CF2 (start from this)
	with CurrentFormat do
	begin
	  Sides := dsSideSingle;
	  TracksPerSide := 40;
	  SectorsPerTrack := 9;
	  SectorSize := 512;
	  GapRW := 42;
	  GapFormat := 82;
	  ResTracks := 1;
	  DirBlocks := 2;
    BlockSize := 1024;
	  FillerByte := 229;
    FirstSector := 1;
    Interleave := 1;
    SkewSide := 0;
    SkewTrack := 0;
  end;

  // And make appropriate changes
  case ItemIndex of
		1: // Amstrad PCW CF2DD
			with CurrentFormat do
	     	begin
          Sides := dsSideDoubleAlternate;
			    TracksPerSide := 80;
			    DirBlocks := 4;
          BlockSize := 2048;
	   	end;
     2: // Amstrad CPC System
     	with CurrentFormat do
        begin
        	FirstSector := 65;
          Interleave := 2;
        end;
     3: // Amstrad CPC data
     	with CurrentFormat do
        begin
          ResTracks := 0;
				  FirstSector := 193;
          Interleave := 2;
        end;
     4: // HiForm 203K (Chris Pile)
     	with CurrentFormat do
        begin
				  TracksPerSide := 42;
          SectorsPerTrack := 10;
          GapFormat := 22;
          GapRW := 12;
          Interleave := 3;
        end;
     5: // Supermat 192K (Ian Collier)
     	with CurrentFormat do
        begin
          TracksPerSide := 40;
          SectorsPerTrack := 10;
          DirBlocks := 3;
          GapFormat := 23;
          GapRW := 12;
        end;
     6: // Ultra208 (Chris Pile)
     	with CurrentFormat do
        begin
        	TracksPerSide := 42;
          SectorsPerTrack := 10;
          DirBlocks := 2;
          ResTracks := 0;
          Interleave := 3;
          SkewTrack := 2;
          GapFormat := 22; // Puts 128 into the spec block!?
          GapRW := 12;
        end;
     7: // Amstrad CPC IBM
     	with CurrentFormat do
        begin
        	SectorsPerTrack := 8;
          FirstSector := 1;
          Interleave := 2;
          GapFormat := 80;
        end;
      8: // SAM Coupe
      with CurrentFormat do
        begin
          Sides := dsSideDoubleAlternate;
			    TracksPerSide := 80;
          SectorsPerTrack := 10;
        end;
	end;
  CurrentFormat.FDCSectorSize := GetFDCSectorSize(CurrentFormat.SectorSize);

	UpdateDetails;
end;

// Temp hack until we persist the formatters properly
function TfrmNew.IsPlus3Format: Boolean;
var
	IsFormat: Boolean;
begin
	IsFormat := True;
  with CurrentFormat do
  begin
	  if Sides <> dsSideSingle then IsFormat := False;
	  if TracksPerSide <> 40 then IsFormat := False;
	  if SectorsPerTrack <> 9 then IsFormat := False;
	  if SectorSize <> 512 then IsFormat := False;
	  if GapRW <> 42 then IsFormat := False;
	  if GapFormat <> 82 then IsFormat := False;
	  if ResTracks <> 1 then IsFormat := False;
	  if DirBlocks <> 2 then IsFormat := False;
    if BlockSize <> 1024 then IsFormat := False;
  end;
	Result := IsFormat;
end;

procedure TfrmNew.cboSidesChange(Sender: TObject);
begin
	CurrentFormat.Sides := TDSKSpecSide(cboSides.ItemIndex);
	UpdateSummary;
end;

procedure TfrmNew.edtTracksChange(Sender: TObject);
begin
	CurrentFormat.TracksPerSide := udTracks.Position;
	UpdateSummary;
end;

procedure TfrmNew.edtSectorsChange(Sender: TObject);
begin
	CurrentFormat.SectorsPerTrack := udSectors.Position;
	UpdateSummary;
end;

procedure TfrmNew.edtSecSizeChange(Sender: TObject);
begin
	CurrentFormat.SectorSize := udSecSize.Position;
	UpdateSummary;
end;

procedure TfrmNew.edtGapRWChange(Sender: TObject);
begin
	CurrentFormat.GapRW := udGapRW.Position;
	UpdateSummary;
end;

procedure TfrmNew.edtGapFormatChange(Sender: TObject);
begin
	CurrentFormat.GapFormat := udGapFormat.Position;
	UpdateSummary;
end;

procedure TfrmNew.edtResTracksChange(Sender: TObject);
begin
	CurrentFormat.ResTracks := udResTracks.Position;
	UpdateSummary;
end;

procedure TfrmNew.edtDirBlocksChange(Sender: TObject);
begin
	CurrentFormat.DirBlocks := udDirBlocks.Position;
	UpdateSummary;
end;

procedure TfrmNew.FormShow(Sender: TObject);
begin
  SetCurrentFormat(0);
  lvwFormats.Items[0].Selected := True;
end;

procedure TfrmNew.chkWriteDiskSpecClick(Sender: TObject);
begin
	if chkWriteDiskSpec.Checked then
  	BootOffset := 16
  else
  	BootOffset := 0;
  UpdateSummary;
  UpdateFileDetails;
end;

procedure TfrmNew.chkAdjustClick(Sender: TObject);
begin
	SetShowAdvanced(chkAdjust.Checked);
end;

procedure TfrmNew.SetShowAdvanced(ShowAdvanced: Boolean);
begin
	tabDetails.TabVisible := ShowAdvanced;
end;

procedure TfrmNew.edtSkewTrackChange(Sender: TObject);
begin
	CurrentFormat.SkewTrack := udSkewTrack.Position;
  UpdateSummary;
end;

procedure TfrmNew.edtInterleaveChange(Sender: TObject);
begin
	CurrentFormat.Interleave := udInterleave.Position;
  UpdateSummary;
end;

procedure TfrmNew.edtFirstSectorChange(Sender: TObject);
begin
	CurrentFormat.FirstSector := udFirstSector.Position;
  UpdateSummary;
end;

procedure TfrmNew.cboBootMachineChange(Sender: TObject);
begin
	BootChecksumRequired := True;
  case cboBootMachine.ItemIndex of
     0: BootChecksum := 3;
     1: BootChecksum := 255;
     2: BootChecksum := 1;
  else	BootChecksumRequired := False;
  end;
	UpdateFileDetails;
	UpdateSummary;
end;

procedure TfrmNew.btnBootBinClick(Sender: TObject);
var
 BootFile: TFileStream;
begin
	dlgOpenBoot.FileName := lblBinFile.Caption;
	if (dlgOpenBoot.Execute) then
  begin
		lblBinFile.Caption := dlgOpenBoot.FileName;

     BootFile := TFileStream.Create(dlgOpenBoot.FileName, fmOpenRead or fmShareDenyNone);
     BootSectorSize := BootFile.Read(BootSectorBin,Length(BootSectorBin));
    	BootFile.Free;
  end;
  UpdateFileDetails;
end;

procedure TfrmNew.edtSkewSideChange(Sender: TObject);
begin
	CurrentFormat.SkewSide := udSkewSide.Position;
  UpdateSummary;
end;

procedure TfrmNew.UpdateFileDetails;
var
	Available: Word;
begin
  Available := (CurrentFormat.SectorSize - BootOffset);

  if lvwBootDetails.Items.Count > 0 then
  begin
		if BootSectorSize > 0 then
     begin
		  lblBootType.Visible := True;
       cboBootMachine.Visible := True;
       lblBootDetails.Visible := True;
       lvwBootDetails.Visible := True;

		  with lvwBootDetails do
       begin
			 Items[0].SubItems[0] := Format('%d', [BootOffset]);
			 Items[1].SubItems[0] := Format('%d bytes', [Available]);
			 Items[2].SubItems[0] := Format('%d bytes', [BootSectorSize]);

			 // Size checks
			 if (BootSectorSize > Available) then
				 Items[3].SubItems[0] := 'Truncate';
			 if (BootSectorSize < Available) then
				 Items[3].SubItems[0] := Format('Pad (%.2x)',[CurrentFormat.FillerByte]);
			 if (BootSectorSize = Available) then
				 Items[3].SubItems[0] := 'Perfect';

			 // Checksum stuff
			 if BootChecksumRequired then
				 Items[4].SubItems[0] := Format('%d / %d',[BootChecksum,1])
	       else
				 Items[4].SubItems[0] := 'Not required';
	     end;
  	end
     else
     begin
		  lblBootType.Visible := False;
       cboBootMachine.Visible := False;
       lblBootDetails.Visible := False;
       lvwBootDetails.Visible := False;
     end;
  end;
end;

procedure TfrmNew.tabBootShow(Sender: TObject);
begin
	UpdateFileDetails;
end;

procedure TfrmNew.btnBootClearClick(Sender: TObject);
begin
	BootSectorSize := 0;
  lblBinFile.Caption := '';
  UpdateFileDetails;
end;

procedure TfrmNew.edtBlockSizeChange(Sender: TObject);
begin
	CurrentFormat.BlockSize := udBlockSize.Position;
  UpdateSummary;
end;

end.
