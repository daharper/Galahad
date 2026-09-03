# Project Galahad

[YouTube Short Presentation](https://www.youtube.com/watch?v=2yx6rttjH7U)

*Developed with Delphi Florence.*

Modern engineering types for Delphi, supporting Clean Architecture and pragmatic best practices.

Project Galahad aims to provide a minimal set of opt-in modern types for general Delphi usage, along with a simple, opinionated architecture for building desktop, console, and mobile applications. It remains very much a work in progress, moving toward an initial `v0.1` release via the `Kitae project`.

The name **Galahad** was chosen after King Arthur's knight, pure and of great integrity, who sought the Holy Grail. The Holy Grail, in this sense, is maintainable code. 

**Project Galahad** aims to remain lightweight, client-side, and opt-in. It is not intended to become a full-blown ORM, nor to compete with other solutions that already solve specific problems well. Instead, it offers a focused set of types to support modern coding practices in Delphi.

For example, the TScope type:

```delphi
// Instead of nested try..finally blocks:
var scope: TScope;
begin
  // Automatically freed when the procedure ends
  var list := scope.Owns(TStringList.Create); 
  var map  := scope.Owns(TDictionary<string, string>.Create);
  
  // Optional custom cleanup (Go-style defer)
  scope.Defer(procedure begin 
    Writeln('Cleaning up extra resources...'); 
  end);
  
  list.Add('Galahad makes this easy.');

  // if there is an exception, list is cleaned up, otherwise we want to return it.
  Result := scope.Release(list);
end; 
```

For a more complete and powerful general framework, see the battle-hardened *Spring4D*.

For backend services there are many excellent frameworks, please see *DMVC*, *Dext*, *mORMot*, *Horse*, etc.
