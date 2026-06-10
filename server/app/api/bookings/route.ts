import { NextRequest, NextResponse } from 'next/server';
import pool from '@/lib/db';

// POST /api/bookings — book a slot (concurrency-safe)
// Headers: X-User-Id: user-001
// Body: { "slot_id": 42 }
export async function POST(request: NextRequest) {
  const userId = request.headers.get('x-user-id');
  if (!userId) {
    return NextResponse.json(
      { error: 'X-User-Id header is required' },
      { status: 401 }
    );
  }

  let body: { slot_id?: number };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 });
  }

  const slotId = body.slot_id;
  if (!slotId || typeof slotId !== 'number') {
    return NextResponse.json(
      { error: 'slot_id (number) is required in request body' },
      { status: 400 }
    );
  }

  // Use a dedicated client from the pool so we can run a transaction
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // SELECT FOR UPDATE locks this specific row until COMMIT/ROLLBACK
    // If two requests hit this at the same instant, one waits here while the other finishes
    const { rows } = await client.query(
      'SELECT id, status FROM slots WHERE id = $1 FOR UPDATE',
      [slotId]
    );

    if (rows.length === 0) {
      await client.query('ROLLBACK');
      return NextResponse.json({ error: 'Slot not found' }, { status: 404 });
    }

    if (rows[0].status === 'booked') {
      await client.query('ROLLBACK');
      return NextResponse.json(
        { error: 'Slot already booked', code: 'SLOT_TAKEN' },
        { status: 409 }
      );
    }

    // Mark slot as booked
    await client.query(
      'UPDATE slots SET status = $1 WHERE id = $2',
      ['booked', slotId]
    );

    // Create the booking record
    const bookingResult = await client.query(
      `INSERT INTO bookings (user_id, slot_id)
       VALUES ($1, $2)
       RETURNING id, user_id, slot_id, booked_at`,
      [userId, slotId]
    );

    await client.query('COMMIT');

    return NextResponse.json(bookingResult.rows[0], { status: 201 });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[POST /api/bookings]', err);
    return NextResponse.json({ error: 'Booking failed' }, { status: 500 });
  } finally {
    // Always release the client back to the pool
    client.release();
  }
}
