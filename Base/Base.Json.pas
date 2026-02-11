{-----------------------------------------------------------------------------------------------------------------------
  Project:     Galahad
  Unit:        Base.Json
  Author:      David Harper
  License:     MIT
  History:     2026-08-02 Initial version 0.1
  Purpose:     Provides simple JSON wrappers and utility functions.
-----------------------------------------------------------------------------------------------------------------------}

unit Base.Json;

interface

uses
  System.SysUtils,
  System.Json,
  Rest.Json,
  Base.Core,
  Base.Integrity;

type
    /// <summary>
    ///  Provides JSON convenience methods.
    /// </summary>
    Json = record
      /// <summary>Returns a TJSONValue from JSON text.</summary>
      class function Parse(const aJsonText: string): TJSONValue; static;

      /// <summary>Returns a TJSONObject from JSON text.</summary>
      class function ParseObject(const aJsonText: string): TJSONObject; static;

      /// <summary>Returns a TJSONArray from JSON text.</summary>
      class function ParseArray(const aJsonText: string): TJSONArray; static;

      /// <summary>Returns the user model T from JSON text.</summary>
      class function ParseType<T: class, constructor>(const aJsonText: string):T; static;

      /// <summary>Returns a JSON text representation of the instance.</summary>
      class function ToString<T:class>(const aInstance: T): string; static;

      /// <summary>Clones an object using JSON serialization.</summary>
      class function Clone<T:class, constructor>(const aInstance: T): T; static;

      /// <summary>Returns a TJSONObject from JSON text.</summary>
      class function AsObject(const aJsonText: string): TResult<TJSONObject>; static;

      /// <summary>Returns a TJSONArray, or error, from JSON text wrapped in a TResult.</summary>
      class function AsArray(const aJsonText: string): TResult<TJSONArray>; static;

      /// <summary>Returns a user model T, or error, from JSON text wrapped in a TResult.</summary>
      class function AsType<T: class, constructor>(const aJsonText: string):TResult<T>; static;

      /// <summary>Returns JSON text of the instance T, or error, wrapped in a TResult.</summary>
      class function AsString<T:class>(const aInstance: T): TResult<string>; static;

      /// <summary>Returns a clone of T, or error, wrapped in a TResult.</summary>
      class function AsClone<T:class, constructor>(const aInstance: T): TResult<T>; static;
    end;

implementation

{----------------------------------------------------------------------------------------------------------------------}
class function Json.Parse(const aJsonText: string): TJSONValue;
begin
  Result := TJSONObject.ParseJSONValue(aJsonText);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Json.ParseObject(const aJsonText: string): TJSONObject;
begin
  Ensure.IsNotBlank(aJsonText, 'Missing JSON text');

  var root := TJSONObject.ParseJSONValue(aJsonText);
  try
    Ensure.IsTrue(Assigned(root), 'Invalid JSON')
          .IsTrue(root is TJSONObject,'Expected JSON object at root');

    Result := TJSONObject(root);

    root := nil;
  finally
    root.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Json.ParseArray(const aJsonText: string): TJSONArray;
begin
  Ensure.IsNotBlank(aJsonText, 'Missing JSON text');

  var root := TJSONObject.ParseJSONValue(aJsonText);
  try
    Ensure.IsTrue(Assigned(root), 'Invalid JSON')
          .IsTrue(root is TJSONArray,'Expected JSON array at root');

    Result := TJSONArray(root);

    root := nil;
  finally
    root.Free;
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Json.ParseType<T>(const aJsonText: string): T;
begin
  Ensure.IsNotBlank(aJsonText, 'Missing JSON text');

  Result := TJson.JsonToObject<T>(aJsonText);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Json.ToString<T>(const aInstance: T): string;
begin
  Ensure.IsTrue(Assigned(aInstance), 'Cannot serialize a nil instance');

  Result := TJson.ObjectToJsonString(aInstance);
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Json.Clone<T>(const aInstance: T): T;
begin
  Ensure.IsTrue(Assigned(aInstance), 'Cannot clone a nil instance');

  Result := TJson.JsonToObject<T>(TJson.ObjectToJsonString(aInstance));
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Json.AsArray(const aJsonText: string): TResult<TJSONArray>;
begin
  try
    Result.SetOk(ParseArray(aJsonText))
  except
    on E:Exception do
      Result.SetErr('Could not parse JSON into an array: ' + E.Message);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Json.AsObject(const aJsonText: string): TResult<TJSONObject>;
begin
  try
    Result.SetOk(ParseObject(aJsonText))
  except
    on E:Exception do
      Result.SetErr('Could not parse JSON into an object: ' + E.Message);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Json.AsString<T>(const aInstance: T): TResult<string>;
const
  ERR = 'Could not serialize %s to JSON: %s';
begin
  try
    Result.SetOk(ToString<T>(aInstance));
  except
    on E:Exception do
      Result.SetErr(ERR, [T.ClassName, E.Message]);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Json.AsType<T>(const aJsonText: string): TResult<T>;
const
  ERR = 'Could not parse JSON into %s: %s';
begin
  try
    Result.SetOk(ParseType<T>(aJsonText));
  except
    on E:Exception do
      Result.SetErr(ERR, [T.ClassName, E.Message]);
  end;
end;

{----------------------------------------------------------------------------------------------------------------------}
class function Json.AsClone<T>(const aInstance: T): TResult<T>;
const
  ERR = 'Could not clone %s: %s';
begin
  try
    Result.SetOk(Clone<T>(aInstance));
  except
    on E:Exception do
      Result.SetErr(ERR, [T.ClassName, E.Message]);
  end;
end;

end.


