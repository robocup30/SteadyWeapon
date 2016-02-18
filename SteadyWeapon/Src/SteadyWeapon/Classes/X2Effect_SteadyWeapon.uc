class X2Effect_SteadyWeapon extends X2Effect_PersistentStatChange config (GameData_SteadyWeapon);

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	EventMgr.RegisterForEvent(EffectObj, 'ObjectMoved', EffectGameState.GenerateCover_ObjectMoved, ELD_OnStateSubmitted, , UnitState);
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', EffectGameState.GenerateCover_AbilityActivated, ELD_OnStateSubmitted, , UnitState);
}

defaultproperties
{
    DuplicateResponse=eDupe_Refresh
	EffectName="SteadyWeapon";
	bRemoveWhenSourceDies=true;
}