import { NextRequest, NextResponse } from 'next/server';
import pool from '@/lib/db';

// GET /api/venues/:id/slots?date=YYYY-MM-DD
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const venueId = parseInt(id, 10);
  const { searchParams } = new URL(request.url);
  const date = searchParams.get('date');

  if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return NextResponse.json({ error: 'Use ?date=YYYY-MM-DD' }, { status: 400 });
  }

  if (isNaN(venueId)) {
    return NextResponse.json({ error: 'Invalid venue id' }, { status: 400 });
  }

  try {
    const venueCheck = await pool.query('SELECT id FROM venues WHERE id = $1', [venueId]);
    if (venueCheck.rows.length === 0) {
      return NextResponse.json({ error: 'Venue not found' }, { status: 404 });
    }

    const { rows } = await pool.query(
      `SELECT
         s.id, s.venue_id, s.date, s.start_time, s.end_time, s.status,
         b.user_id AS booked_by
       FROM slots s
       LEFT JOIN bookings b ON b.slot_id = s.id
       WHERE s.venue_id = $1 AND s.date = $2
       ORDER BY s.start_time`,
      [venueId, date]
    );

    return NextResponse.json(rows);
  } catch (err) {
    console.error(`[GET /api/venues/${id}/slots]`, err);
    return NextResponse.json({ error: 'Failed to fetch slots' }, { status: 500 });
  }
}
