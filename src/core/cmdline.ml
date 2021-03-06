(*
 * Cmdline Module
 * Durand-Marais © 2019
 *)

open Cmdliner
open Monad

let name = "eos"
let version = "0.0"
let licence = "MIT"
let description = "a simple header manager for your projects.
It allows you to manage header in one single JSON file and automatize many features."
let homepage = "https://github.com/maiste/eos"
let bug_reports = "https://github.com/maiste/eos/issues"
let dev_repo = "git://github.com/maiste/eos.git"
let authors = [
  "Etienne (Maiste) Marais <etienne@marais.green>";
  "Xavier (Xavitator) Durand <xavier75013@gmail.com>"
]

let man =
  let bug =
    [ `S Manpage.s_bugs;
      `P ("Report bug : " ^ bug_reports);
    ]
  in
  let author = 
    List.fold_left
      (fun a b ->  a @ [`P b; `Noblank])
      [`S Manpage.s_authors]
      authors
  in
  let contribution =
    [
      `S "CONTRIBUTION";
      `P ("$(b,Licence) : "^licence);
      `P ("$(b,Homepage) : "^homepage);
      `P ("$(b,Dev repository) : "^dev_repo)
    ]
  in
  bug @ contribution @ author

let prompt_list l = List.iter (Printf.printf "%s\n") l

let get_files () = 
  match
    ((Conf.init_json Conf.conf_file) 
     >>= Conf.get_file_regex 
     >>= Finder.get_files) with
  | Ok l -> Ok (prompt_list l)
  | Error msg -> Error (`Msg msg)

(* command corresponding to 'eos files' *)
let files = 
  let doc = "display files tracked by eos." in
  let exits = Term.default_exits in
  Term.(term_result (const get_files $ const ())),
  Term.info "files" ~doc ~exits ~man

(* default command if no-command is matched *)
let default =
  let exits = Term.default_exits in
  Term.(ret (const (`Help (`Pager, None)))),
  Term.info name ~version ~doc:description ~exits ~man

(* list of all eos' command *)
let cmds = 
  [
    files
  ]

let run () = Term.(exit ~term_err:1 @@ eval_choice default cmds)