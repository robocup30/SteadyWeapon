class X2Effect_SteadyWeapon extends X2Effect_PersistentStatChange config (GameData_SteadyWeapon);

var XComGameState_Effect EffectState;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local X2EventManager EventMgr;
	local Object ListenerObj;
	local XComGameState_Unit UnitState;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	EventMgr = `XEVENTMGR;

	EffectState = NewEffectState;
	ListenerObj = self;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(NewEffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(ListenerObj, 'ObjectMoved', SteadyWeapon_ObjectMoved, ELD_OnStateSubmitted,,UnitState);
	EventMgr.RegisterForEvent(ListenerObj, 'AbilityActivated', SteadyWeapon_AbilityActivated, ELD_OnStateSubmitted,,UnitState);
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local X2EventManager EventMgr;
	local Object ListenerObj;

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);
	ListenerObj = self;
	EventMgr = `XEVENTMGR;
	EventMgr.UnRegisterFromEvent(ListenerObj, 'ObjectMoved');
	EventMgr.UnRegisterFromEvent(ListenerObj, 'AbilityActivated');
}

defaultproperties
{
    DuplicateResponse=eDupe_Refresh
	EffectName="SteadyWeapon";
	bRemoveWhenSourceDies=true;
}

simulated function EventListenerReturn SteadyWeapon_ObjectMoved(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_EffectRemoved RemoveContext;
	local XComGameState NewGameState;

	RemoveContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(EffectState);
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, RemoveContext);
	EffectState.RemoveEffect(NewGameState, GameState);
	`TacticalRules.SubmitGameState(NewGameState);

	return ELR_NoInterrupt;
}

function EventListenerReturn SteadyWeapon_AbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Ability AbilityState;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != None)
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		if (AbilityTemplate != None)
		{
			if (AbilityTemplate.Hostility == eHostility_Offensive)
			{
				AbilityState = XComGameState_Ability(GameState.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
				if (AbilityState == None)
					AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

				if (AbilityState != None)
				{
					if (AbilityState.IsAbilityInputTriggered())
					{
						SteadyWeapon_ObjectMoved(EventData, EventSource, GameState, EventID);
					}
				}
			}
		}
	}
	return ELR_NoInterrupt;
}