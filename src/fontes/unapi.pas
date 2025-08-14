unit unAPI;

{$mode ObjFPC}{$H+}

interface

uses
    Classes,
    SysUtils,
    unGenerica,
    mormot.core.base,
    mormot.core.variants,
    mormot.core.os,
    mormot.core.json,
    mormot.core.text,
    mormot.core.data,
    mormot.orm.core,
    mormot.rest.core,
    mormot.rest.memserver,
    mormot.rest.server,
    mormot.rest.http.server,
    mormot.net.client,
    mormot.net.sock;

type
{ TApiServer }

    TApiServer = class
    private
        FStore: TSynDictionary;
        FModel: TOrmModel;
        FRest: TRestServerFullMemory;
        FServerHttp: TRestHttpServer;
    public
        constructor Create;
        destructor Destroy; override;

        procedure Add(Context: TRestServerUriContext);
        procedure Query(Context: TRestServerUriContext);
    end;

implementation

{ TApiServer }

procedure TApiServer.Add(Context: TRestServerUriContext);
var
    lReqJson: TDocVariantData;
    lCorrelationId: RawUtf8;
    liService: Integer;
    lId: RawUtf8;
    lResposta: TDocVariantData;
begin
    lReqJson.InitJson(Context.Call^.InBody, JSON_OPTIONS_FAST);
    lReqJson.GetAsRawUtf8('correlationId', lCorrelationId);
    lReqJson.GetAsInteger('service', liService);

    lId := lCorrelationId + '-' + IntToStr(liService);

    FStore.Add(lId, lReqJson.ToJson);

    lResposta.InitJson('', JSON_OPTIONS_FAST);
    lResposta.AddValue('correlationId', lCorrelationId);
    Context.ReturnsJson(Variant(lResposta), HTTP_SUCCESS);
end;

procedure TApiServer.Query(Context: TRestServerUriContext);
var
    ldFrom: TDateTime;
    ldTo: TDateTime;

    TotalDefault: Integer;
    TotalFallback: Integer;
    AmountDefault: Double;
    AmountFallback: Double;

    I: Integer;
    lItem: RawUtf8;
    liService:Integer;
    lcAmount: Double;
    lData: RawUtf8;
    ldData: TDateTime;

    lJson: TDocVariantData;
    lDefault: TDocVariantData;
    lFallback: TDocVariantData;
    lResposta: TDocVariantData;
begin
    ldFrom := 0;
    ldTo := EncodeDate(3000, 12, 31);

    if Context.InputExists['from'] then
        ldFrom := _Iso8601ToDateTime(Context.InputUtf8['from']);

    if Context.InputExists['to'] then
        ldTo := _Iso8601ToDateTime(Context.InputUtf8['to']);

    TotalDefault:= 0;
    TotalFallback:= 0;
    AmountDefault:= 0;
    AmountFallback:= 0;
    
    for I := 0 to FStore.Count - 1 do
    begin
        lItem:= TRawUtf8DynArray(FStore.Values.Value[0])[I];
        lJson.InitJson(lItem, JSON_OPTIONS_FAST);

        lJson.GetAsRawUtf8('requestedAt', lData);
        ldData:= _Iso8601ToDateTime(lData);

        if (ldData >= ldFrom) and (ldData <= ldTo) then
        begin
            lJson.GetAsInteger('service', liService);
            lJson.GetAsDouble('amount', lcAmount);

            if liService = 0 then
            begin
                Inc(TotalDefault);
                AmountDefault := AmountDefault + lcAmount;
            end
            else
            begin
                Inc(TotalFallback);
                AmountFallback := AmountFallback + lcAmount;
            end;
        end;
    end;

    lDefault.InitObject([
        'totalRequests', TotalDefault,
        'totalAmount', FormatFloat('0.00', AmountDefault)
    ]);

    lFallback.InitObject([
        'totalRequests', TotalFallback,
        'totalAmount', FormatFloat('0.00', AmountFallback)
    ]);

    lResposta.InitObject([
        'default', Variant(lDefault),
        'fallback', Variant(lFallback)
    ]);

    Context.ReturnsJson(Variant(lResposta), HTTP_SUCCESS);
end;

constructor TApiServer.Create;
begin
    inherited Create;

    FStore := TSynDictionary.Create(TypeInfo(TRawUtf8DynArray), TypeInfo(TRawUtf8DynArray));

    FModel:= TOrmModel.Create([]);

    FRest:= TRestServerFullMemory.Create(FModel);
    FRest.ServiceMethodRegister('add', @add, true);
    FRest.ServiceMethodRegister('query', @query, true);;

    FServerHttp:= TRestHttpServer.Create('9090', [FRest], '+', useHttpSocket, FNumMaxWorkersSocket, secNone, '', '', [rsoAllowSingleServerNoRoot, rsoOnlyJsonRequests]);
end;

destructor TApiServer.Destroy;
begin
    FServerHttp.Free;
    FRest.Free;
    FModel.Free;
    inherited Destroy;
end;

end.

