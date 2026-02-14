# Project Galahad

<img width="270" height="395" alt="Galahad" src="https://github.com/user-attachments/assets/73dfd30c-6dfe-422e-92cb-00cf36e9ac4b" />

*Developed for Delphi Florence.*

Modern engineering types for Delphi, allowing Clean Architecture and best practices.

The repository should take shape over the next few weeks, in the meantime there will be lots of churn.

Initial project push (version 0.1) involved:

- Pulling code from a personal project
- Clarifying policies
- Refactoring
- Writing tests

The second phase has just begun which is a basic application (named Escape) that uses the Galahad base types.

This is the application, hardening, and polishing of the initial version 0.1 release.

Project.groupproj opens both projects; for individual projects open Galahad.dproj or Escape.dproj.

Once the dust settles, I'll provide documentation.

The name **Galahad** was chosen after King Arthur's knight, pure and of great integrity, who sought the Holy Grail.

The Holy Grail, in this sense, is maintainable code. 

**Project Galahad** aims to be a minimal and opinionated set of types to support modern coding practices.

For example, the TScope type:

```delphi
// Instead of nested try..finally blocks:
var scope: TScope;
begin
  // Automatically freed when the procedure ends
  var List := scope.Owns(TStringList.Create); 
  var Map  := scope.Owns(TDictionary<string, string>.Create);
  
  // Optional custom cleanup (Go-style defer)
  scope.Defer(procedure begin 
    Writeln('Cleaning up extra resources...'); 
  end);
  
  List.Add('Galahad makes this easy.');

  // if there is an exception, List is cleaned up, otherwise we want to return it.
  Result := scope.Release(List);
end; 
```

Subsequent releases will seek to expand upon the initial limited core feature set.

This project is experimental and exploratory in nature:

- **Project Galahad** does not aim to be an ORM, nor a framework, it is a set of types
- **Project Escape** only implements what it needs for demonstrating and dogfooding the base types

For a more complete and powerful general framework, see the battle-hardened *Spring4D*.

For backend services there are many excellent frameworks such as *DMVC*, *Dext*, *mORMot*, *Horse*, and others.

For more information, please see the [Project Hub](https://www.beyondvelocity.com/).
