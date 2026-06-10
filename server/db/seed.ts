import pool from '../lib/db';

const VENUES = [
  { name: 'Smash Arena', sport_type: 'badminton', location: 'Koramangala, Bengaluru', price_inr: 400 },
  { name: 'The Turf Club', sport_type: 'turf', location: 'Indiranagar, Bengaluru', price_inr: 800 },
  { name: 'Court Side', sport_type: 'badminton', location: 'HSR Layout, Bengaluru', price_inr: 350 },
  { name: 'Green Field Turf', sport_type: 'turf', location: 'Whitefield, Bengaluru', price_inr: 700 },
  { name: 'Ace Badminton Club', sport_type: 'badminton', location: 'Jayanagar, Bengaluru', price_inr: 450 },
];

function getDates(days: number): string[] {
  const dates: string[] = [];
  for (let i = 0; i < days; i++) {
    const d = new Date();
    d.setDate(d.getDate() + i);
    dates.push(d.toISOString().split('T')[0]);
  }
  return dates;
}

// 6AM to 10PM hourly
function generateTimeSlots(): { start: string; end: string }[] {
  const slots = [];
  for (let hour = 6; hour < 22; hour++) {
    slots.push({
      start: `${String(hour).padStart(2, '0')}:00`,
      end: `${String(hour + 1).padStart(2, '0')}:00`,
    });
  }
  return slots;
}

async function seed() {
  const client = await pool.connect();
  try {
    console.log('seeding venues...');
    const venueIds: number[] = [];

    for (const v of VENUES) {
      const res = await client.query(
        `INSERT INTO venues (name, sport_type, location, price_inr)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT DO NOTHING
         RETURNING id`,
        [v.name, v.sport_type, v.location, v.price_inr]
      );
      if (res.rows[0]) venueIds.push(res.rows[0].id);
    }

    console.log('seeding slots...');
    const dates = getDates(7);
    const timeSlots = generateTimeSlots();

    for (const venueId of venueIds) {
      for (const date of dates) {
        for (const ts of timeSlots) {
          await client.query(
            `INSERT INTO slots (venue_id, date, start_time, end_time)
             VALUES ($1, $2, $3, $4)
             ON CONFLICT (venue_id, date, start_time) DO NOTHING`,
            [venueId, date, ts.start, ts.end]
          );
        }
      }
    }

    console.log('done');
  } finally {
    client.release();
    await pool.end();
  }
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
