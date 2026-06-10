import { NextRequest, NextResponse } from 'next/server';
import pool from '@/lib/db';

// GET /api/users/:id/bookings — full booking history with slot + venue details
export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;

  try {
    const { rows } = await pool.query(
      `SELECT
         b.id AS booking_id, b.booked_at,
         s.id AS slot_id, s.date, s.start_time, s.end_time, s.status,
         v.id AS venue_id, v.name AS venue_name, v.sport_type, v.location, v.price_inr
       FROM bookings b
       JOIN slots s ON s.id = b.slot_id
       JOIN venues v ON v.id = s.venue_id
       WHERE b.user_id = $1
       ORDER BY b.booked_at DESC`,
      [id]
    );

    return NextResponse.json(rows);
  } catch (err) {
    console.error(`[GET /api/users/${id}/bookings]`, err);
    return NextResponse.json({ error: 'Failed to fetch bookings' }, { status: 500 });
  }
}
