; PureRGBnote: CHANGED: FIREWALL is now a dedicated burn status move, like THUNDER_WAVE.

FirewallEffect_:
	ld hl, wEnemyMonStatus
	ld de, wEnemyMonType1
	ldh a, [hWhoseTurn]
	and a
	jp z, .gotTurn
	ld hl, wBattleMonStatus
	ld de, wBattleMonType1
.gotTurn
	ld a, [hl]
	and a ; does the target already have a status ailment?
	jr nz, .didntAffect
; check if the target is immune to burn due to types
	ld a, [de]
	cp FIRE
	jr z, .doesntAffect
	inc de
	ld a, [de]
	cp FIRE
	jr z, .doesntAffect
	push hl
	callfar MoveHitTest
	pop hl
	ld a, [wMoveMissed]
	and a
	jr nz, .didntAffect
	set BRN, [hl]
	callfar HalveAttackDueToBurn
	ld c, 30
	rst DelayFrames
	callfar PlayCurrentMoveAnimation
	jpfar PrintBurnText
.didntAffect
	ld c, 50
	rst DelayFrames
	jpfar PrintDidntAffectText
.doesntAffect
	ld c, 50
	rst DelayFrames
	jpfar PrintDoesntAffectText

; input de = wBattleMonStatus or wEnemyMonStatus
AutoBurnEffect::
	ld h, d
	ld l, e
	set BRN, [hl]
	callfar HalveAttackDueToBurn
	jpfar PrintBurnText