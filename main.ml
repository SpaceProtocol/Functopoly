open Player
open Command 
open Board
open Yojson

(** [get_num_players] is the number of players  *)
let get_num_players = 
  ANSITerminal.(print_string [red]
                  "\n\nWelcome to the 3110 Text Monopoly Game engine.\n");
  print_endline "How many players are playing the game? \n";
  print_string  "> ";
  match read_line () with
  | exception End_of_file -> 0
  | no_players -> int_of_string no_players

(** takes in a 0 just for shits and returns a number rolled by 2 dice*)
let dice zero =
  (Random.int 6) + (Random.int 6) + 2 + zero

let get_current_player_name players =
  List.nth players.player_names (players.current_player)

(** [get_player_names n] is the list of player names entered by the user *)
let rec get_player_names n = 
  match n with
  | 0 -> []
  | _ -> 
    print_string "Please enter the game name for the next player \n";
    print_string  "> ";
    match read_line () with
    | exception End_of_file -> []
    | player_name -> player_name::(get_player_names (n - 1))

(** [print_string_list lst] prints out a list of strings [lst]*)
let rec print_string_list lst =
  match lst with
  | [] -> ()
  | h::t -> print_string h; print_string_list lst

let command_list =
  "\nHere's the list of commands you can \
   run:\n\
   roll: Rolls the dice for the next player.\n\
   help: Prints the list of commands you can run.\n\
   inventory <player_name>: Prints the inventory for <player_name>.\n\
   buy: Buys a property if you landed on one.\n\
   sell <property_name>: Sells the <property_name> property you own.\n\
   quit: Quits the game and displays the winner.\n"

(** [play_game_recursively ]*)
let rec play_game_recursively str_command player_info current_player board =
  let parsed_command = (try Command.parse str_command with 
      | Malformed -> (print_endline "The command you entered was Malformed :( \
                                     Please try again.";
                      print_string  "> ";
                      match read_line () with
                      | exception End_of_file -> exit 0
                      | str -> play_game_recursively str
                                 player_info current_player board)
      | Empty -> (print_endline "The command you entered was Empty.\
                                 Please try again."; 
                  print_string  "> ";
                  match read_line () with
                  | exception End_of_file -> exit 0;
                  | str -> play_game_recursively str player_info current_player
                             board)) in
  match parsed_command with
  | Quit -> print_endline "Sad to see you go. Exiting game now."; exit 0;
  | Roll -> 
    let new_player_info = (Player.new_player player_info) in 
    let current_name = (get_current_player_name new_player_info) in
    print_string current_name;
    (print_string ", it's your turn now! Your current location is "; 
     print_int (Player.get_current_location new_player_info);
     print_string  "> ";
     match read_line () with
     | exception End_of_file -> exit 0;
     | str -> play_game_recursively str new_player_info current_player board)
  | Help -> (print_endline command_list;
             print_string  "> ";
             match read_line () with
             | exception End_of_file -> exit 0
             | str -> play_game_recursively str player_info current_player board
            )
  | Inventory player_name -> (print_endline "This would be your inventory";

                              print_string  "> ";
                              match read_line () with
                              | exception End_of_file -> exit 0
                              | str -> play_game_recursively str player_info
                                         current_player board)
  | Buy -> (print_endline "You cannot buy properties yet";
            print_string  "> ";
            match read_line () with
            | exception End_of_file -> exit 0
            | str -> play_game_recursively str player_info current_player board)

  (* Player enters 'upgrade'
     Displays list of upgradeable properties (will need to somehow check what
     groups of properties the players owns completely)
     Then chooses property and upgrade "amount"
     Finish
  *)
  | Upgrade -> (print_endline "You cannot upgrade properties yet";
                print_string  "> ";
                match read_line () with
                | exception End_of_file -> exit 0
                | str -> play_game_recursively str player_info
                           current_player board)
  (*
  display player-property menu
   who do you wanna trade with?
   player x
   which property do you wanna trade?
   property y
   what price do you want to sell for? (syntax: <cash>, <property>)
   player x, do you accept that price? (<accept>/<reject>)
  *)
  | Trade -> (print_endline "You cannot trade properties yet";
              print_string  "> ";
              match read_line () with
              | exception End_of_file -> exit 0
              | str -> play_game_recursively str player_info
                         current_player board)



(** *)
let start_game board = 
  let num_players = get_num_players in
  let player_names = get_player_names num_players in

  let initial_player_info = ANSITerminal.(print_string [blue]
                                            command_list);
    Player.to_players num_players player_names in
  print_string "Player 1 goes first: ";
  print_string  "> ";
  match read_line () with
  | exception End_of_file -> exit 0
  | str -> play_game_recursively str initial_player_info "" board

(* print_string_list player_names; print_string (string_of_int num_players) *)

let rec main_helper file_name =
  try from_json (Basic.from_file file_name)
  with _ -> print_endline "Looks like something is \
                           wrong with the file \
                           name :( Please try again."; 
    print_string  "> ";
    match read_line () with
    | exception End_of_file -> exit 0
    | file_name -> main_helper file_name


let rec main () =
  print_endline "Please enter the name of the game file you want to load.\n";
  print_string  "> ";
  match read_line () with
  | exception End_of_file -> exit 0
  | file_name -> start_game (main_helper file_name)

(* Execute the game engine. *)
let x = main ()

