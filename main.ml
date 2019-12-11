open Player
open Command 
open Board
open Yojson
open Indices

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
   endturn: Ends the current player's turn and moves the dice to the next 
   player.\n\
   help: Prints the list of commands you can run.\n\
   inventory <player_name>: Prints the inventory for <player_name>.\n\
   buy: Buys a property if you landed on one.\n\
   trade: Initiates a trade sequence.\n\
   upgrade: Displays upgradeable properties and then allows you to upgrade 
   them. \n\
   quit: Quits the game and displays the winner.\n"


(* ====== START TRADE HELPERS ======= *)

let valid_property player property = true (* TODO *)

(* trader2 is a string but trader1 is a player *)

(*let strip str = 
  let str = Str.replace_first (Str.regexp "^ +") "" str in
  Str.replace_first (Str.regexp " +$") "" str;; *)

let valid_player trader1 trader2 = 
  List.mem (String.trim trader2) trader1.player_names

let rec parse_cash = function
  | [] -> []
  | h::t -> try (int_of_string h)::(parse_cash t) 
    with Failure e -> (0)::(parse_cash t)

let rec remove_spaces = function
  | [] -> []
  | h::t -> (String.trim h)::(remove_spaces t)

let rec remove_zeroes = function
  | [] -> 0
  | h::t -> if h <> 0 then h else (remove_zeroes t)

let rec parse_property = function
  | [] -> ""
  | h::t -> try (int_of_string h); (parse_property t) 
    with Failure e -> h

let rec remove_empties = function
  | [] -> ""
  | h::t -> if h <> "" then h else (remove_empties t)

let parse_price str property_to_trade =
  if (String.contains str ',') then (let comma_split = String.split_on_char ',' 
                                         str in
                                     let spaces_removed = remove_spaces 
                                         comma_split in
                                     let cash = remove_zeroes (parse_cash 
                                                                 spaces_removed)
                                     in
                                     let property = parse_property 
                                         spaces_removed in 
                                     (cash, property, property_to_trade)
                                    ) else (try ((int_of_string (String.trim 
                                                                   str)), "", 
                                                 property_to_trade)
                                            with Failure e -> (0, (String.trim 
                                                                     str), 
                                                               property_to_trade) 
                                           )

let print_price cash property trader2 = 
  print_string "Cash: ";
  print_endline (string_of_int cash);
  print_string "Property: ";
  print_endline property;
  print_endline "";
  print_string trader2

(** Let the bargaining begin! *)
let rec bargaining trader1_price trader1 trader2 property_to_trade =
  let (cash, property, property_to_trade) =  parse_price trader1_price 
      property_to_trade in
  let () = print_price cash property trader2 in
  print_endline ", do you accept or reject this price?";
  print_string  "> ";
  match read_line () with
  | exception End_of_file -> exit 0
  | accept_or_reject -> 
    if (String.trim accept_or_reject) = "accept" then 
      (cash, property, property_to_trade) (** TODO: update the player and 
                                              property info *)
    else if ((String.trim accept_or_reject) = "reject") then (
      print_string (get_current_player_name trader1);
      print_endline ", your price was rejected. Please propose a better price
        or type endbargain to call off the trade. \
                     Please enter the price in one of the following ways:\
                     1. An int cash value. Example: 10 \
                     2. The name of a property belonging to the player you're 
                     trading with. Example: x \
                     3. Int cash value followed by a comma and the desired 
                     property name. Example: 10, x
        ";
      print_string  "> ";
      match read_line () with
      | exception End_of_file -> exit 0
      | better_price -> if (String.trim accept_or_reject) = "endbargain" then 
          (0, "", property_to_trade)
        else bargaining better_price trader1 trader2 property_to_trade
    )
    else (print_endline "Invalid response. Please re-enter your decision";
          bargaining trader1_price trader1 trader2 property_to_trade)

let rec property_trade trader1 =
  print_endline "Which property do you want to trade?";
  print_string  "> ";
  match read_line () with
  | exception End_of_file -> exit 0
  | property_to_trade -> 
    if (not(valid_property trader1 property_to_trade)) then 
      (print_endline "Invalid property. Please re-enter the name of the 
    property you want to trade.";
       property_trade trader1)
    else property_to_trade

let rec execute_trade trader1 trader2 =
  if (not(valid_player trader1 trader2)) 
  then (print_endline "Invalid player name. Please re-enter the name of the 
  player you want to trade with.";
        print_string  "> ";
        match read_line () with
        | exception End_of_file -> exit 0
        | trade_partner -> 
          execute_trade trader1 trade_partner)
  else let property_to_trade = property_trade trader1 in
    print_endline "What price do you want to trade at? \n\
                   (Please enter the price in one of the following ways:\n\
                   1. An int cash value. Example: 10 \n\
                   2. The name of a property belonging to the player you're 
                   trading with. Example: x \n\
                   3. Int cash value followed by a comma and the desired 
                   property name. Example: 10, x \n\
                   )";
    print_string  "> ";
    match read_line () with
    | exception End_of_file -> exit 0
    | str -> bargaining str trader1 trader2 property_to_trade

(* ======= END TRADE HELPERS ======= *)

(** gets property name*)
let buy_helper player_info board=
  Player.get_property_name (get_property (Player.get_current_location 
                                            player_info) board)


let rec get_player_id_from_name player_names name acc=
  match player_names with
  |[]-> acc
  |h::t when h = name -> acc
  |h::t -> get_player_id_from_name t name (acc+1)

let rec properties_to_string lst =
  let rec helper acc = function
    | [] -> acc
    | (name,_)::t -> if (List.length t) = 0 then
        helper (acc ^ name) t
      else if (List.length t) = 1 then
        helper (acc ^ name ^ ", and ") t
      else
        helper (acc ^ name ^ ", ") t
  in
  helper "" lst


let validate_command_order cmd1 cmd2 =
  ((String.trim cmd1 = "roll" && String.trim cmd2 = "roll")
   || (String.trim cmd1 = "endturn" && String.trim cmd2 = "endturn")
   || (String.trim cmd1 = "buy" && String.trim cmd2 = "roll")
   || (String.trim cmd1 = "buy" && String.trim cmd2 = "buy")
   || (String.trim cmd1 = "endturn" && String.trim cmd2 = "buy")
  )

let is_property tile = 
  match tile with
  | PropertyTile a -> true
  | _ -> false 

let rec tax_loop str_command player_info board =
(print_endline "";print_string  "> ";
       match read_line () with
       | "percent" -> print_endline "We have taken 10% of your money muahaha"; Player.update_player_percent player_info board
       | "flat" -> print_endline "We have taken $200 of your money for... tax... purposes... don't ask questions"; Player.update_player_flat_tax player_info board 200
       | anything_else -> print_string "that is an invalid entry. Please choose percent or flat";
       tax_loop str_command player_info board
       |_-> failwith "tax_loop")

(** [play_game_recursively ]*)
let rec play_game_recursively prev_cmd str_command player_info board =
  if validate_command_order prev_cmd str_command
  then (
    print_string "You cannot enter a ";
    print_string str_command;
    print_string " after ";
    print_string prev_cmd;
    print_endline ". Please re-enter your next command.";
    print_string  "> ";
    match read_line () with
    | exception End_of_file -> exit 0
    | str -> play_game_recursively prev_cmd str player_info board
  )
  else
    let parsed_command = (try Command.parse str_command with
        | Malformed -> (print_endline "The command you entered was Malformed :(\
                                       Please try again.";
                        print_string  "> ";
                        match read_line () with
                        | exception End_of_file -> exit 0
                        | str -> play_game_recursively prev_cmd str
                                   player_info board)
        | Empty -> (print_endline "The command you entered was Empty.\
                                   Please try again."; 
                    print_string  "> ";
                    match read_line () with
                    | exception End_of_file -> exit 0;
                    | str -> play_game_recursively prev_cmd str player_info
                               board)) in
    match parsed_command with
    | Quit -> print_endline "Sad to see you go. Exiting game now."; exit 0;
    | Roll ->
 let update_player_roll = (roll_new_player player_info board) in
     if ((Player.get_current_location update_player_roll) = 4) then (print_endline "You have landed on income tax! Please choose percent or flat";
     let new_info = tax_loop str_command update_player_roll board in
     (print_endline "";print_string  "> ";
       match read_line () with
       | exception End_of_file -> exit 0;
       | str -> play_game_recursively str_command str new_info board)
    (**if current location of update player roll is 4 then readline for tax otherwise continue regularly*) 
      ) else 
      (print_endline "";print_string  "> ";
       match read_line () with
       | exception End_of_file -> exit 0;
       | str -> play_game_recursively str_command str update_player_roll board)
    | EndTurn ->
      let current_player = Player.get_current_player player_info in
      (* print_endline (string_of_int current_player.money); *)
      if current_player.money < 0 then
        begin
          (* TODO: This returns information pertaining to the properties of
             the forfeited playing changing hands. This needs to be reflected in
             the data structures passed in with each call to play_game_
             recursively *)
          let auction_info = Auction.auction current_player player_info in
          let post_forfeit_player_info = Player.forfeit_player current_player 
              player_info board auction_info in
          let current_name = (get_current_player_name post_forfeit_player_info) 
          in
          print_endline ("Player " ^ current_name ^ ", it's your turn now! Your 
          current location is "
                         ^ string_of_int (Player.get_current_location 
                                            post_forfeit_player_info)); 
          print_endline "";
          print_string  "> ";
          match read_line () with
          | exception End_of_file -> exit 0;
          | str -> play_game_recursively str_command str 
                     post_forfeit_player_info board
        end
      else
        let new_player_info = (Player.new_player player_info board) in 
        let current_name = (get_current_player_name new_player_info) in
        print_string current_name;
        (print_string ", it's your turn now! Your current location is "; 
         print_int (Player.get_current_location new_player_info);
         print_string  "> ";
         match read_line () with
         | exception End_of_file -> exit 0;
         | str -> play_game_recursively str_command str new_player_info board
        )
    | Help -> (
        print_endline command_list;
        print_string  "> ";
        match read_line () with
        | exception End_of_file -> exit 0
        | str -> play_game_recursively prev_cmd str player_info board
      )
    | Inventory player_name -> (
        print_string player_name; print_endline "'s inventory:";
        let money = (Player.inventory_money_helper player_info.player_list 0 
                       (get_player_id_from_name player_info.player_names player_name 0)) in
        let list = (Player.inventory_helper player_info.player_list [] 
                      (get_player_id_from_name player_info.player_names player_name 0)) in 
        (Player.list_printer list);
        print_string player_name; print_string "'s money: "; print_int money;
        print_endline "";
        print_string  "> ";
        match read_line () with
        | exception End_of_file -> exit 0
        | str -> play_game_recursively prev_cmd str player_info board)
    | Buy -> let update_player_buy = (Player.buy_new_player player_info board) 
      in
      let curr_location = get_current_location player_info in
      let property = get_property curr_location board in
      if (not(is_property property)) then (
        print_endline "You cannot buy on a tile that isn't a property! Please 
        enter a valid command.";
        print_string  "> ";
        match read_line () with
        | exception End_of_file -> exit 0
        | str -> play_game_recursively str_command str player_info board)
      

      else if ((get_owner_id property) <> -1) then (
        print_endline "You cannot buy a property that is already owned by 
        someone! 
        However, you can trade if you'd like. Please enter a valid command.";
        print_string  "> ";
        match read_line () with
        | exception End_of_file -> exit 0
        | str -> play_game_recursively str_command str player_info board)
      else
        let prop_name = buy_helper player_info board in (
          print_string "Congrats you now own ";
          print_endline (get_property_name (get_property (get_current_location 
                                                            player_info) board));
          print_string  "> ";
          match read_line () with
          | exception End_of_file -> exit 0
          | str -> play_game_recursively str_command str update_player_buy 
                     (Board.buy_update_board board update_player_buy.current_player 
                        prop_name))
    (* Player enters 'upgrade'
       Displays list of upgradeable properties (will need to somehow check what
       groups of properties the players owns completely)
       Then chooses property and upgrade "amount"
       Finish
    *)
    | Upgrade -> let current_player_id = (player_info.current_player) in
      let color_groups = Upgrade.get_color_groups current_player_id board in
      let upgradeable_properties = Upgrade.get_upgradeable_properties 
          current_player_id board color_groups in
      let prop_string = properties_to_string upgradeable_properties in
      if (List.length upgradeable_properties = 0) then
        begin
          print_endline "You do not have any upgradeable properties at this 
          moment.";
          print_string  "> ";
          match read_line () with
          | exception End_of_file -> exit 0
          | str -> play_game_recursively prev_cmd str player_info board
        end
      else
        begin
          print_endline ("You can upgrade the following properties: " ^ 
                         prop_string);
          print_string  "> ";
          match read_line () with
          | exception End_of_file -> exit 0
          | name -> if List.mem_assoc name upgradeable_properties then
              let index = List.assoc name upgradeable_properties in
              let update_player_upgrade = (Player.upgrade_new_player player_info
                                             board index) in
              print_endline name;
              let new_board = {board with property_tiles = (Upgrade.update_level
                                                              index board.property_tiles)} in
              print_endline ("You have upgraded " ^ name);
              print_string  "> ";
              match read_line () with
              | exception End_of_file -> exit 0
              | str -> play_game_recursively prev_cmd str update_player_upgrade 
                         new_board
            else
              begin
                print_endline "That is not a property you can upgrade.";
                print_string  "> ";
                match read_line () with
                | exception End_of_file -> exit 0
                | str -> play_game_recursively prev_cmd str player_info board
              end
        end

  (*
   display player-property menu
   who do you wanna trade with?
   player x
   which property do you wanna trade?
   property y
   what price do you want to sell for? (syntax: <cash>, <property>)
   player x, do you accept that price? (<accept>/<reject>)
  *)
    | Trade -> (
        print_endline "print player property menu here";
        (* Get property tile and then owner from *)
        print_endline "Who do you want to trade with?";
        print_string  "> ";
        match read_line () with
        | exception End_of_file -> exit 0
        | trader2 -> let (cash, property, property_to_trade) = execute_trade 
                         player_info trader2 in
          let player1 = (get_player_id_from_name player_info.player_names 
                           (get_current_player_name player_info) 0) in
          let player2 = (get_player_id_from_name player_info.player_names 
                           trader2 0) in
          print_endline "Trade complete.";
          print_string  "> ";
          match read_line () with
          | exception End_of_file -> exit 0
          | str -> (
              let updated_player_info = trade_new_player player_info player1
                  player2 property_to_trade property (board.property_tiles) cash in
              play_game_recursively prev_cmd str updated_player_info board)
      )



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
  | str -> play_game_recursively "" str initial_player_info board

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
  Random.self_init ();
  print_endline "Please enter the name of the game file you want to load.\n";
  print_string  "> ";
  match read_line () with
  | exception End_of_file -> exit 0
  | file_name -> start_game (main_helper file_name)

(* Execute the game engine. *)
let x = main ()

