class X2Effect_SteadyWeapon extends X2Effect_PersistentStatChange config (GameData_SteadyWeapon);

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Effect_SteadyWeapon SWEffectState;
	local X2EventManager EventMgr;
	local Object ListenerObj;
	local XComGameState_Unit UnitState;

	EventMgr = `XEVENTMGR;

	if (GetSteadyWeaponComponent(NewEffectState) == none)
	{
		//create component and attach it to GameState_Effect, adding the new state object to the NewGameState container
		SWEffectState = XComGameState_Effect_SteadyWeapon(NewGameState.CreateStateObject(class'XComGameState_Effect_SteadyWeapon'));
		SWEffectState.InitComponent();
		NewEffectState.AddComponentObject(SWEffectState);
		NewGameState.AddStateObject(SWEffectState);
	}

	ListenerObj = SWEffectState;
	if (ListenerObj == none)
	{
		`Redscreen("SteadyWeapon: Failed to find SteadyWeapon Component when registering listener");
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(NewEffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(ListenerObj, 'ObjectMoved', SWEffectState.SteadyWeapon_ObjectMoved, ELD_OnStateSubmitted,,UnitState);
	EventMgr.RegisterForEvent(ListenerObj, 'AbilityActivated', SWEffectState.SteadyWeapon_AbilityActivated, ELD_OnStateSubmitted,,UnitState);
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local X2EventManager EventMgr;
	local Object ListenerObj;

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	ListenerObj = GetSteadyWeaponComponent(RemovedEffectState);
	EventMgr = `XEVENTMGR;
	EventMgr.UnRegisterFromEvent(ListenerObj, 'ObjectMoved');
	EventMgr.UnRegisterFromEvent(ListenerObj, 'AbilityActivated');
}

static function XComGameState_Effect_SteadyWeapon GetSteadyWeaponComponent(XComGameState_Effect Effect)
{
	if (Effect != none) 
		return XComGameState_Effect_SteadyWeapon(Effect.FindComponentObject(class'XComGameState_Effect_SteadyWeapon'));
	return none;
}

defaultproperties
{
    DuplicateResponse=eDupe_Refresh
	EffectName="SteadyWeapon";
	bRemoveWhenSourceDies=true;
}