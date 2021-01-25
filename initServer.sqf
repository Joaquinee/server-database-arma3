#define FETCH_CONST(var) (call var)
#define EXTDB "extDB3" callExtension
//Init de la DAtabase + Protcol de sécurité
InitDatabase_fnc = {
	private["_database","_protocol","_protocol_options","_return","_result","_random_number","_extDB_SQL_CUSTOM_ID"];

	_database = [_this,0,"",[""]] call BIS_fnc_param;
	_protocol = [_this,1,"",[""]] call BIS_fnc_param;
	_protocol_options = [_this,2,"",[""]] call BIS_fnc_param;
	_return = false;

	if ( isNil {uiNamespace getVariable "extDB_SQL_CUSTOM_ID"}) then
	{
		// extDB Version
		_result = "extDB3" callExtension "9:VERSION";

		diag_log format ["extDB3: Version: %1", _result];
		if(_result == "") exitWith {diag_log "extDB3: Failed to Load"; false};
		//if ((parseNumber _result) < 20) exitWith {diag_log "Error: extDB version 20 or Higher Required";};

		// extDB Connect to Database
		_result = parseSimpleArray ("extDB3" callExtension format["9:ADD_DATABASE:%1", _database]);
		if (_result select 0 isEqualTo 0) exitWith {diag_log format ["extDB3: Error Database: %1", _result]; false};
		diag_log "extDB3: Connected to Database";

		// Generate Randomized Protocol Name
		_random_number = round(random(999999));
		_extDB_SQL_CUSTOM_ID = str(_random_number);
		extDB_SQL_CUSTOM_ID = compileFinal _extDB_SQL_CUSTOM_ID;

		// extDB Load Protocol
		_result = parseSimpleArray ("extDB3" callExtension format["9:ADD_DATABASE_PROTOCOL:%1:%2:%3:%4", _database, _protocol, _extDB_SQL_CUSTOM_ID, _protocol_options]);
		if ((_result select 0) isEqualTo 0) exitWith {diag_log format ["extDB3: Error Database Setup: %1", _result]; false};

		diag_log format ["extDB3: Initalized %1 Protocol", _protocol];

		// extDB3 Lock
		"extDB3" callExtension "9:LOCK";
		diag_log "extDB3: Locked";

		// Save Randomized ID
		uiNamespace setVariable ["extDB_SQL_CUSTOM_ID", _extDB_SQL_CUSTOM_ID];
		_return = true;
	}
	else
	{
		extDB_SQL_CUSTOM_ID = compileFinal str(uiNamespace getVariable "extDB_SQL_CUSTOM_ID");
		diag_log "extDB3: Already Setup";
		_return = true;
	};

_return
};
  

// Cette function permet de traiter la requrete
/*
	_result = 	[_query, 1]  call asyncCall  --  le 1 true si valeur existe
	_result = 	[_query, 2]  call asyncCall  --  le 2 revoie la requete sous forme de tableau
*/
asyncCall = {
	private ["_queryStmt","_mode","_multiarr","_queryResult","_key","_return","_loop"];
		_queryStmt = [_this,0,"",[""]] call BIS_fnc_param;
		_mode = [_this,1,1,[0]] call BIS_fnc_param;
		_multiarr = [_this,2,false,[false]] call BIS_fnc_param;

		_key = EXTDB format ["%1:%2:%3",_mode,FETCH_CONST(extDB_SQL_CUSTOM_ID),_queryStmt];

		if (_mode isEqualTo 1) exitWith {true};

		_key = call compile format ["%1",_key];
		_key = (_key select 1);
		_queryResult = EXTDB format ["4:%1", _key];

		//Make sure the data is received
		if (_queryResult isEqualTo "[3]") then {
			for "_i" from 0 to 1 step 0 do {
				if (!(_queryResult isEqualTo "[3]")) exitWith {};
				_queryResult = EXTDB format ["4:%1", _key];
			};
		};

		if (_queryResult isEqualTo "[5]") then {
			_loop = true;
			for "_i" from 0 to 1 step 0 do { // extDB3 returned that result is Multi-Part Message
				_queryResult = "";
				for "_i" from 0 to 1 step 0 do {
					_pipe = EXTDB format ["5:%1", _key];
					if (_pipe isEqualTo "") exitWith {_loop = false};
					_queryResult = _queryResult + _pipe;
				};
			if (!_loop) exitWith {};
			};
		};
		_queryResult = call compile _queryResult;
		if ((_queryResult select 0) isEqualTo 0) exitWith {diag_log format ["extDB3: Protocol Error: %1", _queryResult]; []};
		_return = (_queryResult select 1);
		if (!_multiarr && count _return > 0) then {
			_return = (_return select 0);
		};

		_return;
};




private _timeSt = diag_tickTime;
i_ready = false;


// Pour charger INI ["altislife","SQL_CUSTOM","fichier.ini"] call InitDatabase_fnc le ini doit être dans @extDB3\sql_custom
// De base on veux des requrete SQL normal
waitUntil {["altislife","SQL",""] call InitDatabase_fnc};
diag_log "-------------------------------------------------------------";
diag_log "-------------------- InaLife Serveur ------------------------";
diag_log "-------------------------------------------------------------";

diag_log "-------------------------------------------------------------";
diag_log format["Total Execution Time %1 seconds", (diag_tickTime - _timeSt)];
diag_log "-------------------------------------------------------------";

i_ready = true;
publicVariable "i_ready";



//TON CODE

//Example de requete :

addMissionEventHandler ["PlayerConnected",
{
	params ["_id", "_uid", "_name", "_jip", "_owner", "_idstr"];

	_query = format ["SELECT * FROM players WHERE pid='%1'", _uid];
	_result = [_query,2] call asyncCall;
	_result_un = [_query,1] call asyncCall;

	diag_log format["REQUEST Avec 2 : %1", _result];
	diag_log format["REQUEST Avec 1 : %1", _result_un];
}];


