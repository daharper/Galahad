# Project Galahad
[Please see here for more](https://www.beyondvelocity.com/114)

<img width="270" height="395" alt="Galahad" src="https://github.com/user-attachments/assets/73dfd30c-6dfe-422e-92cb-00cf36e9ac4b" />

*Developed with Delphi Florence.*

Modern engineering types for Delphi, supporting Clean Architecture and pragmatic best practices.

Project Galahad aims to provide a minimal set of opt-in modern types for general Delphi usage, along with a simple, opinionated architecture for building desktop, console, and mobile applications. It remains very much a work in progress, moving toward an initial `v0.1` release.

Trying to evolve everything at once became a little overwhelming. Rather than rushing toward a release, development is now being driven through focused demonstration applications.

These demonstrations put useful pressure on the library, surfacing assumptions, oversights, and awkward edges: UI integration, data access, dependency management, state handling, conventions, infrastructure boundaries, and the practical realities of working in Delphi rather than in a language or ecosystem the patterns were originally designed around.

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

For backend services there are many excellent frameworks such as *DMVC*, *Dext*, *mORMot*, *Horse*, and others.
