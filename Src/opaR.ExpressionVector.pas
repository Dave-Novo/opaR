unit opaR.ExpressionVector;

{-------------------------------------------------------------------------------

opaR: object pascal for R

Copyright (C) 2015-2016 Sigma Sciences Ltd.

Originator: Robert L S Devine

Unless you have received this program directly from Sigma Sciences Ltd under
the terms of a commercial license agreement, then this program is licensed
to you under the terms of version 3 of the GNU Affero General Public License.
Please refer to the AGPL licence document at:
http://www.gnu.org/licenses/agpl-3.0.txt for more details.

This program is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY, INCLUDING
THOSE OF NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

-------------------------------------------------------------------------------}

{-------------------------------------------------------------------------------

TExpressionVector is a wrapper around the SEXPREC generated by the R_ParseVector
function. This contrasts with other vector types which are wrappers for R
vectors generated by Rf_allocVector.

-------------------------------------------------------------------------------}

interface

uses

  opaR.Utils,
  opaR.ProtectedPointer,
  //opaR.Engine_Intf,
  opaR.SEXPREC,
  opaR.Vector,
  opaR.Interfaces,
  opaR.Expression;

type
  TExpressionVector = class(TRVector<IExpression>, IExpressionVector)
  protected
    function GetDataSize: integer; override;
    function GetValue(ix: integer): IExpression; override;
    procedure SetValue(ix: integer; value: IExpression); override;
  public
    constructor Create(engine: IREngine; pExpr: PSEXPREC);
    function GetArrayFast: TArray<IExpression>; override;
    procedure SetVectorDirect(values: TArray<IExpression>); override;
  end;

implementation

uses
  opaR.EngineExtension;

{ TExpressionVector }

//------------------------------------------------------------------------------
constructor TExpressionVector.Create(engine: IREngine; pExpr: PSEXPREC);
begin
  inherited Create(engine, pExpr);
end;
//------------------------------------------------------------------------------
function TExpressionVector.GetArrayFast: TArray<IExpression>;
var
  i: integer;
begin
  SetLength(result, VectorLength);
  for i := 0 to VectorLength - 1 do
    result[i] := GetValue(i);
end;
//------------------------------------------------------------------------------
function TExpressionVector.GetDataSize: integer;
begin
  result := SizeOf(PSEXPREC);
end;
//------------------------------------------------------------------------------
function TExpressionVector.GetValue(ix: integer): IExpression;
var
  PPtr: PSEXPREC;
  pp: TProtectedPointer;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    PPtr := PSEXPREC(PPointerArray(DataPointer)^[ix]);

    if (PPtr = nil) or (PPtr = TEngineExtension(Engine).NilValue) then
      result := nil
    else
      // -- Lifetime management of the returned TExpression is the
      // -- responsibility of the calling code.
      result := TExpression.Create(Engine, PPtr);
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
//-- Note that TExpressionVector does not get involved in any lifetime management
//-- of TExpression objects - in SetValue we just copy the pointer value to the
//-- internal R vector.
procedure TExpressionVector.SetValue(ix: integer; value: IExpression);
var
  PData: PSEXPREC;
  pp: TProtectedPointer;
begin
  if (ix < 0) or (ix >= VectorLength) then
    raise EopaRException.Create('Error: Vector index out of bounds');

  pp := TProtectedPointer.Create(self);
  try
    if value = nil then
      PData := TEngineExtension(Engine).NilValue
    else
      PData := value.Handle;

    PPointerArray(DataPointer)^[ix] := PData;
  finally
    pp.Free;
  end;
end;
//------------------------------------------------------------------------------
procedure TExpressionVector.SetVectorDirect(values: TArray<IExpression>);
var
  i: integer;
begin
  for i := 0 to Length(values) - 1 do
    SetValue(i, values[i]);
end;

end.
