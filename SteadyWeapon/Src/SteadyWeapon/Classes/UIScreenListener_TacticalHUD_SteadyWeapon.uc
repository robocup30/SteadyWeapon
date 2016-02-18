class UIScreenListener_TacticalHUD_SteadyWeapon extends UIScreenListener;

// Workaround to add the evac all ability to each xcom unit. Loop over all units on tactical UI load and
// add the ability to each one that doesn't already have it.
event OnInit(UIScreen Screen)
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local int i;
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Locate the evac all ability template
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate('SteadyWeapon');

	// Add the ability to each squad member that doesn't already have it.
	for (i = 0; i < XComHQ.Squad.Length; ++i) 
	{
		EnsureAbilityOnUnit(XComHQ.Squad[i], AbilityTemplate);
	}
}

// Ensure the unit represented by the given reference has the EvacAll ability
function EnsureAbilityOnUnit(StateObjectReference UnitStateRef, X2AbilityTemplate AbilityTemplate)
{
	local XComGameState_Unit UnitState, NewUnitState;
	local XComGameState_Ability AbilityState;
	local StateObjectReference StateObjectRef;
	local XComGameState NewGameState;

	if(UnitStateRef.ObjectID == 0)
	{
		return;
	}

	// Find the current unit state for this unit
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectId(UnitStateRef.ObjectID));

	// Loop over all the abilities they have
	foreach UnitState.Abilities(StateObjectRef) 
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(StateObjectRef.ObjectID));

		// If the unit already has this ability, don't add a new one.
		if (AbilityState.GetMyTemplateName() == 'SteadyWeapon')
		{
			return;
		}
	}

	// Construct a new unit game state for this unit, adding an instance of the ability
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add SteadyWeapon Ability");
	NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
	AbilityState = AbilityTemplate.CreateInstanceFromTemplate(NewGameState);
	AbilityState.InitAbilityForUnit(NewUnitState, NewGameState);
	NewGameState.AddStateObject(AbilityState);
	NewUnitState.Abilities.AddItem(AbilityState.GetReference());
	NewGameState.AddStateObject(NewUnitState);

	// Submit the new state
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

defaultProperties
{
    ScreenClass = UITacticalHUD
}