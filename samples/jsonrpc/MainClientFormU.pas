unit MainClientFormU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Net.HttpClientComponent, Vcl.StdCtrls,
  System.Net.URLClient, System.Net.HttpClient, Data.DB, Vcl.Grids, Vcl.DBGrids,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.ComCtrls, Vcl.ExtCtrls;

type
  TForm10 = class(TForm)
    DataSource1: TDataSource;
    FDMemTable1: TFDMemTable;
    FDMemTable1Code: TIntegerField;
    FDMemTable1Name: TStringField;
    GroupBox1: TGroupBox;
    edtValue1: TEdit;
    edtValue2: TEdit;
    btnSubstract: TButton;
    edtResult: TEdit;
    edtReverseString: TEdit;
    btnReverseString: TButton;
    edtReversedString: TEdit;
    GroupBox2: TGroupBox;
    edtUserName: TEdit;
    btnGetUser: TButton;
    lbPerson: TListBox;
    GroupBox3: TGroupBox;
    edtFilter: TEdit;
    edtGetCustomers: TButton;
    DBGrid1: TDBGrid;
    GroupBox4: TGroupBox;
    edtFirstName: TLabeledEdit;
    edtLastName: TLabeledEdit;
    chkMarried: TCheckBox;
    dtDOB: TDateTimePicker;
    btnSave: TButton;
    dtNextMonday: TDateTimePicker;
    btnAddDay: TButton;
    btnInvalid1: TButton;
    btnInvalid2: TButton;
    procedure btnSubstractClick(Sender: TObject);
    procedure btnReverseStringClick(Sender: TObject);
    procedure edtGetCustomersClick(Sender: TObject);
    procedure btnGetUserClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnAddDayClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnInvalid1Click(Sender: TObject);
    procedure btnInvalid2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form10: TForm10;

implementation

uses
  MVCFramework.JSONRPC, MVCFramework.Serializer.JsonDataObjects,
  JsonDataObjects, MVCFramework.Serializer.Commons, MVCFramework.DataSet.Utils,
  BusinessObjectsU;

{$R *.dfm}

procedure JSONRPCExec(const aJSONRPCURL: string; const aJSONRPCRequest: TJSONRPCRequest; out aJSONRPCResponse: TJSONRPCResponse);
var
  lSS: TStringStream;
  lHttpResp: IHTTPResponse;
  lHTTP: THTTPClient;
begin
  lSS := TStringStream.Create(aJSONRPCRequest.AsJSONString);
  try
    lSS.Position := 0;
    lHTTP := THTTPClient.Create;
    try
      lHttpResp := lHTTP.Post('http://localhost:8080/jsonrpc', lSS, nil,
        [
        TNetHeader.Create('content-type', 'application/json'),
        TNetHeader.Create('accept', 'application/json')
        ]);
      if (lHttpResp.StatusCode <> 204) then
      begin
        aJSONRPCResponse := TJSONRPCResponse.Create;
        try
          aJSONRPCResponse.AsJSONString := lHttpResp.ContentAsString;
          if Assigned(aJSONRPCResponse.Error) then
            raise Exception.CreateFmt('Error [%d]: %s', [aJSONRPCResponse.Error.Code, aJSONRPCResponse.Error.ErrMessage]);
        except
          aJSONRPCResponse.Free;
          raise;
        end;
      end;
    finally
      lHTTP.Free;
    end;
  finally
    lSS.Free;
  end;
end;

procedure TForm10.btnAddDayClick(Sender: TObject);
var
  lReq: TJSONRPCRequest;
  lResp: TJSONRPCResponse;
begin
  lReq := TJSONRPCRequest.Create;
  try
    lReq.Method := 'getnextmonday';
    lReq.RequestID := Random(1000);
    lReq.Params.Add(dtNextMonday.Date);
    JSONRPCExec('http://localhost:8080/jsonrpc', lReq, lResp);
    try
      dtNextMonday.Date := ISOTimeStampToDateTime(lResp.Result.AsString);
    finally
      lResp.Free;
    end;
  finally
    lReq.Free;
  end;
end;

procedure TForm10.btnGetUserClick(Sender: TObject);
var
  lReq: TJSONRPCRequest;
  lResp: TJSONRPCResponse;
  lJSON: TJsonObject;
begin
  lbPerson.Clear;
  lReq := TJSONRPCRequest.Create;
  try
    lReq.Method := 'getuser';
    lReq.RequestID := Random(1000);
    lReq.Params.Add(edtUserName.Text);
    JSONRPCExec('http://localhost:8080/jsonrpc', lReq, lResp);
    try
      if Assigned(lResp.Error) then
        raise Exception.Create(lResp.Error.ErrMessage);

      // Remember that TObject descendants (but TDataset, TJDOJSONObject and TJDOJSONArray)
      // are serialized as JSON objects
      lJSON := lResp.Result.AsObject as TJsonObject;
      lbPerson.Items.Add('First Name:'.PadRight(15) + lJSON.S['firstname']);
      lbPerson.Items.Add('Last Name:'.PadRight(15) + lJSON.S['lastname']);
      lbPerson.Items.Add('Married:'.PadRight(15) + lJSON.B['married'].ToString(TUseBoolStrs.True));
      lbPerson.Items.Add('DOB:'.PadRight(15) + DateToStr(lJSON.D['dob']));
    finally
      lResp.Free;
    end;
  finally
    lReq.Free;
  end;
end;

procedure TForm10.btnInvalid1Click(Sender: TObject);
var
  lReq: TJSONRPCRequest;
  lResp: TJSONRPCResponse;
begin
  lReq := TJSONRPCRequest.Create;
  try
    lReq.Method := 'invalidmethod1';
    lReq.Params.Add(1);
    JSONRPCExec('http://localhost:8080/jsonrpc', lReq, lResp);
    try
      ShowMessage(lResp.Error.ErrMessage);
    finally
      lResp.Free;
    end;
  finally
    lReq.Free;
  end;
end;

procedure TForm10.btnInvalid2Click(Sender: TObject);
var
  lReq: TJSONRPCRequest;
  lResp: TJSONRPCResponse;
begin
  lReq := TJSONRPCRequest.Create;
  try
    lReq.Method := 'invalidmethod2';
    lReq.Params.Add(1);
    JSONRPCExec('http://localhost:8080/jsonrpc', lReq, lResp);
    try
      ShowMessage(lResp.Error.ErrMessage);
    finally
      lResp.Free;
    end;
  finally
    lReq.Free;
  end;

end;

procedure TForm10.btnReverseStringClick(Sender: TObject);
var
  lReq: TJSONRPCRequest;
  lResp: TJSONRPCResponse;
begin
  lReq := TJSONRPCRequest.Create;
  try
    lReq.Method := 'reversestring';
    lReq.RequestID := Random(1000);
    lReq.Params.Add(edtReverseString.Text);
    JSONRPCExec('http://localhost:8080/jsonrpc', lReq, lResp);
    try
      edtReversedString.Text := lResp.Result.AsString;
    finally
      lResp.Free;
    end;
  finally
    lReq.Free;
  end;
end;

procedure TForm10.btnSaveClick(Sender: TObject);
var
  lPerson: TPerson;
  lReq: TJSONRPCRequest;
  lResp: TJSONRPCResponse;
begin
  lReq := TJSONRPCRequest.Create;
  try
    lReq.Method := 'saveperson';
    lReq.RequestID := Random(1000);
    lPerson := TPerson.Create;
    lReq.Params.Add(lperson);
    lPerson.FirstName := edtFirstName.Text;
    lPerson.LastName := edtLastName.Text;
    lPerson.Married := chkMarried.Checked;
    lPerson.DOB := dtDOB.Date;
    JSONRPCExec('http://localhost:8080/jsonrpc', lReq, lResp);
    try
      ShowMessage('Person saved with ID = ' + lResp.Result.AsInteger.ToString);
    finally
      lResp.Free;
    end;
  finally
    lReq.Free;
  end;
end;

procedure TForm10.btnSubstractClick(Sender: TObject);
var
  lReq: TJSONRPCRequest;
  lResp: TJSONRPCResponse;
begin
  lReq := TJSONRPCRequest.Create;
  try
    lReq.Method := 'subtract';
    lReq.RequestID := Random(1000);
    lReq.Params.Add(StrToInt(edtValue1.Text));
    lReq.Params.Add(StrToInt(edtValue2.Text));

    JSONRPCExec('http://localhost:8080/jsonrpc', lReq, lResp);
    try
      edtResult.Text := lResp.Result.AsInteger.ToString;
    finally
      lResp.Free;
    end;
  finally
    lReq.Free;
  end;
end;

procedure TForm10.edtGetCustomersClick(Sender: TObject);
var
  lReq: TJSONRPCRequest;
  lResp: TJSONRPCResponse;
begin
  FDMemTable1.Active := False;
  lReq := TJSONRPCRequest.Create;
  try
    lReq.Method := 'getcustomers';
    lReq.RequestID := Random(1000);
    lReq.Params.Add(edtFilter.Text);
    JSONRPCExec('http://localhost:8080/jsonrpc', lReq, lResp);
    try
      FDMemTable1.Active := True;
      FDMemTable1.LoadFromTValue(lResp.Result);
    finally
      lResp.Free;
    end;
  finally
    lReq.Free;
  end;
end;

procedure TForm10.FormCreate(Sender: TObject);
begin
  dtNextMonday.Date := Date;
end;

end.
