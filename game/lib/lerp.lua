function Lerp( delta, from, to )

	if ( delta > 1 ) then return to end
	if ( delta < 0 ) then return from end

	return from + ( to - from ) * delta

end

function LerpPos( delta, from, to )

	if ( delta > 1 ) then return to end
	if ( delta < 0 ) then return from end

	return { Lerp(delta, from[1], to[1]), Lerp(delta, from[2], to[2]) }

end

function LerpVector( delta, from, to )

	if ( delta > 1 ) then return to end
	if ( delta < 0 ) then return from end

	return Vector( Lerp(delta, from.x, to.x), Lerp(delta, from.y, to.y) )

end