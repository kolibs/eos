(* 
 * Module to read config.json's file.
 * We need to call [init_json] before any use.
 * DURAND - MARAIS © 2019
 *)

open Ezjsonm
open Monad


(* Name of the config's file *)
let conf_file = "./.eos/config.json"
let auto_file = "./.eos/auto"
let template_dir = "./.eos/template"

(* init [json] variable *)
let init_json path =
  try
    let file = open_in path in
    Ok (from_channel file)
  with
  | Sys_error msg | Parse_error (_,msg) ->
    let msg = Printf.sprintf "[Error] can't init json (%s): %s" path msg in
    Error msg

(* Get the corresponding field of [str_path] in [json] *)
let member js str_path =
  try
    Ok (find js str_path)
  with Not_found ->
    let path = String.concat "" str_path in
    let msg = Printf.sprintf "[Error] %s" path in
    Error msg


(* Transform a json [js] into a String *)
let get_json_string js =
  try
    if js = `Null then
      Error "[Error] can't read json field"
    else 
      Ok (js |> get_string)
  with Parse_error _ -> 
    Error "[Error] wrong type"


(* Get string content corresponding to [name] field *)
let get_name json =
  member json ["name"]
  >>=  get_json_string


(* Concatenate two lists of type choice *)
let concat_choice_list o1 o2 =
  match o1, o2 with
  | Ok l1, Ok l2 -> Ok (List.rev_append l1 l2)
  | _ -> Error "[Error] can't reverse and append list"


(* Return a string choice list *)
let map_choice str l1 =
  Ok (List.map (
      fun a -> Filename.concat str a 
    ) l1)


(* Get all regex corresponding to the [files] content *)
let get_file_regex json =
  let rec aux acc js =
    match js with
    | `O l ->
      let append_assoc_opt acc (str, js) =
        concat_choice_list (
          (aux (Ok []) js)
          >>= map_choice str
        ) acc
      in List.fold_left append_assoc_opt acc l
    | `A l -> List.fold_left aux acc l
    | `String str ->
      acc >>= (fun elt -> Ok(str :: elt))
    | `Null -> Ok []
    | _ -> Error "[Error] can't find regex"
  in
  member json ["files"]
  >>= aux (Ok [])

(* Get content corresponding to [template] field *)
let get_user_template json = 
  member json ["template"] 

(* Update the old header field *)
let update_auto header =
  Writer.write auto_file header
  |> ignore

(* Get the old header *)
let get_old_header value =
  Reader.read_file value

let get_template_path js =
  let add_dir dir =
    template_dir ^ "/" ^ dir |> choice
  in
  member js ["model"]
  >>= get_json_string
  >>= add_dir

(* Get the current template file *)
let get_template_json js =
  get_template_path js
  >>= init_json
 
