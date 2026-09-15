/**
 * Editorial content for Sagar Tours and Travels.
 *
 * Anything that would be a factual claim about the business (ratings, customer
 * counts, years in operation, fares, distances, travel times, reviews) carries
 * `isPlaceholder: true`. Components render those values with a muted
 * "to be confirmed" treatment so nothing on the page reads as a verified claim
 * until the business supplies real figures.
 */

export const stats = {
  /** Flip to false once the business confirms these figures. */
  isPlaceholder: true,
  note:
    'Ratings and totals shown are placeholders pending confirmation from the business.',
  items: [
    { icon: 'clock', value: '24/7', label: 'Taxi Service', verified: true },
    { icon: 'star', value: '4.9★', label: 'Google Rating' },
    { icon: 'group', value: '1000+', label: 'Happy Customers' },
    { icon: 'shield', value: '10+', label: 'Years of Experience' },
  ],
};

export const services = [
  {
    id: 'airport-taxi',
    icon: 'flight',
    title: 'Airport Taxi',
    description:
      'Reliable pickup and drop services to and from Dr. Babasaheb Ambedkar International Airport, Nagpur.',
  },
  {
    id: 'local-taxi',
    icon: 'city',
    title: 'Local Taxi',
    description:
      'Comfortable taxis for shopping, meetings, hospital visits, sightseeing and everyday travel across Nagpur.',
  },
  {
    id: 'outstation-taxi',
    icon: 'route',
    title: 'Outstation Taxi',
    description:
      'Comfortable one-way and round-trip taxi services from Nagpur to destinations across Maharashtra and nearby states.',
  },
  {
    id: 'one-way-taxi',
    icon: 'oneWay',
    title: 'One-Way Taxi',
    description: 'Convenient point-to-point travel with transparent pricing.',
  },
  {
    id: 'corporate-travel',
    icon: 'briefcase',
    title: 'Corporate Travel',
    description:
      'Professional transportation solutions for companies, employees, executives and business travellers.',
  },
  {
    id: 'wedding-events',
    icon: 'celebration',
    title: 'Wedding & Event Transportation',
    description:
      'Reliable transportation for weddings, functions, events and special occasions.',
  },
  {
    id: 'railway-transfer',
    icon: 'train',
    title: 'Railway Station Transfer',
    description:
      'Convenient pickup and drop services to Nagpur Railway Station and nearby railway stations.',
  },
  {
    id: 'tour-travel',
    icon: 'map',
    title: 'Tour & Travel',
    description:
      'Taxi and transportation solutions for family trips, group tours and sightseeing journeys.',
  },
];

export const benefits = [
  {
    icon: 'badge',
    title: 'Professional Drivers',
    description:
      'Experienced and courteous drivers focused on a comfortable journey.',
  },
  {
    icon: 'sparkle',
    title: 'Clean & Well-Maintained Cars',
    description:
      'Vehicles maintained for cleanliness, comfort and reliability.',
  },
  {
    icon: 'rupee',
    title: 'Transparent Pricing',
    description: 'Clear pricing with no unnecessary surprises.',
  },
  {
    icon: 'clock',
    title: 'On-Time Pickup',
    description:
      'We value your time and aim to provide punctual pickup and drop services.',
  },
  {
    icon: 'headset',
    title: '24/7 Support',
    description: 'Assistance whenever you need to plan or book a ride.',
  },
  {
    icon: 'phone',
    title: 'Easy Booking',
    description:
      'Book through phone, WhatsApp or the online booking form.',
  },
];

/** Fares are placeholders until the business supplies a rate card. */
export const FARE_PLACEHOLDER = 'Starting from ₹XX/km';

export const fleet = [
  {
    id: 'dzire',
    image: 'fleetDzire',
    name: 'Maruti Suzuki Dzire',
    category: 'Sedan',
    seats: '4+1 Seats',
    bags: '2 Bags',
    features: ['AC'],
  },
  {
    id: 'ertiga',
    image: 'fleetErtiga',
    name: 'Maruti Suzuki Ertiga',
    category: 'MUV',
    seats: '6+1 Seats',
    bags: '4 Bags',
    features: ['AC'],
  },
  {
    id: 'carens',
    image: 'fleetCarens',
    name: 'Kia Carens',
    category: 'Premium MUV',
    seats: '6+1 Seats',
    bags: '4 Bags',
    features: ['AC'],
  },
  {
    id: 'innova-crysta',
    image: 'fleetInnova',
    name: 'Toyota Innova Crysta',
    category: 'Premium MUV',
    seats: '6+1 Seats',
    bags: '4+ Bags',
    features: ['Dual AC'],
  },
  {
    id: 'premium-sedan',
    image: 'fleetSedan',
    name: 'Premium Sedan',
    category: 'Premium Sedan',
    seats: '4+1 Seats',
    bags: '2 Bags',
    features: ['AC', 'Comfort Interior'],
  },
  {
    id: 'tempo-traveller',
    image: 'fleetTempo',
    name: 'Tempo Traveller',
    category: 'Group Travel',
    seats: '12–17+ Seats',
    bags: 'Large Luggage Capacity',
    features: ['AC / Non-AC'],
  },
];

/** Distances and durations are placeholders until verified. */
export const ROUTE_DISTANCE_PLACEHOLDER = 'Approx. XXX km';
export const ROUTE_DURATION_PLACEHOLDER = 'Approx. XX hrs';

export const routes = [
  { id: 'tadoba', to: 'Tadoba', blurb: 'Tiger reserve getaway' },
  { id: 'pench', to: 'Pench', blurb: 'National park transfer' },
  { id: 'amravati', to: 'Amravati', blurb: 'Intercity travel' },
  { id: 'jabalpur', to: 'Jabalpur', blurb: 'Interstate journey' },
  { id: 'pachmarhi', to: 'Pachmarhi', blurb: 'Hill station trip' },
  { id: 'raipur', to: 'Raipur', blurb: 'Interstate journey' },
  { id: 'hyderabad', to: 'Hyderabad', blurb: 'Long-distance ride' },
  { id: 'mumbai', to: 'Mumbai', blurb: 'Long-distance ride' },
  { id: 'chikhaldara', to: 'Chikhaldara', blurb: 'Hill station trip' },
  { id: 'kanha', to: 'Kanha', blurb: 'National park transfer' },
].map((r) => ({
  ...r,
  from: 'Nagpur',
  distance: ROUTE_DISTANCE_PLACEHOLDER,
  duration: ROUTE_DURATION_PLACEHOLDER,
  isPlaceholder: true,
}));

export const destinations = [
  {
    id: 'tadoba',
    image: 'destTadoba',
    name: 'Tadoba',
    description:
      'Andhari Tiger Reserve, a popular wildlife destination for weekend trips from Nagpur.',
  },
  {
    id: 'pench',
    image: 'destPench',
    name: 'Pench',
    description:
      'A well-known national park on the Maharashtra–Madhya Pradesh border, close to Nagpur.',
  },
  {
    id: 'pachmarhi',
    image: 'destPachmarhi',
    name: 'Pachmarhi',
    description:
      'A quiet hill station in the Satpura range, suited to longer family road trips.',
  },
  {
    id: 'kanha',
    image: 'destKanha',
    name: 'Kanha',
    description:
      'One of central India’s larger national parks, a favourite for multi-day safaris.',
  },
  {
    id: 'chikhaldara',
    image: 'destChikhaldara',
    name: 'Chikhaldara',
    description:
      'Vidarbha’s hill station, known for its viewpoints and cooler weather.',
  },
  {
    id: 'ramtek',
    image: 'destRamtek',
    name: 'Ramtek',
    description:
      'A historic temple town near Nagpur, easy to cover as a short day trip.',
  },
];

export const steps = [
  {
    number: '01',
    title: 'Tell Us Your Trip',
    description: 'Enter your pickup, destination and travel details.',
  },
  {
    number: '02',
    title: 'Get Your Fare',
    description: 'Receive the appropriate fare for your journey.',
  },
  {
    number: '03',
    title: 'Confirm Your Booking',
    description:
      'Confirm your ride through phone, WhatsApp or online booking.',
  },
  {
    number: '04',
    title: 'Enjoy Your Journey',
    description:
      'Your professional driver arrives at the scheduled pickup point.',
  },
];

/**
 * Reviews are intentionally empty of real content. Fabricated testimonials are
 * not acceptable, so these render as clearly labelled placeholder cards until
 * reviews are imported from the Google Business Profile.
 */
export const reviews = {
  isPlaceholder: true,
  rating: '4.9★',
  note:
    'Review cards are placeholders. They will be replaced with verified reviews imported from the Google Business Profile.',
  items: [
    { service: 'Airport Taxi' },
    { service: 'Outstation Taxi' },
    { service: 'Local Taxi' },
    { service: 'Tour & Travel' },
  ].map((item, i) => ({
    ...item,
    id: `review-${i + 1}`,
    name: 'Customer name',
    body:
      'Verified Google review text will appear here once reviews are imported from the Google Business Profile.',
  })),
};

export const faqs = [
  {
    q: 'How can I book a taxi in Nagpur?',
    a: 'You can book in three ways: fill in the booking form on this page, send your trip details on WhatsApp, or call us directly. Share your pickup point, destination, date and time, and we will confirm a vehicle for you.',
  },
  {
    q: 'Do you provide airport pickup and drop services?',
    a: 'Yes. We run pickups and drops for Dr. Babasaheb Ambedkar International Airport, Nagpur. For arrivals, share your flight number so the driver can adjust to the actual landing time.',
  },
  {
    q: 'Do you provide one-way taxi services?',
    a: 'Yes. One-way trips are available for point-to-point travel, so you only pay for the direction you are travelling instead of a full round trip.',
  },
  {
    q: 'Do you offer outstation taxis from Nagpur?',
    a: 'Yes. We cover outstation travel from Nagpur to destinations across Maharashtra and neighbouring states, on both one-way and round-trip basis.',
  },
  {
    q: 'Can I book a taxi 24/7?',
    a: 'Booking requests are accepted around the clock. Late-night and early-morning trips are easier to arrange when you book a little in advance so a driver can be assigned.',
  },
  {
    q: 'Which payment methods do you accept?',
    a: 'Accepted payment methods have not been confirmed yet and will be listed here shortly. Please confirm the options when you make your booking.',
  },
  {
    q: 'Are tolls and parking charges included?',
    a: 'Tolls, state permits and parking are generally billed separately from the trip fare. Ask for a full breakdown when you receive your quote so you know exactly what is included.',
  },
  {
    q: 'How far in advance should I book?',
    a: 'Same-day bookings are often possible. For airport runs, outstation trips, larger vehicles such as a Tempo Traveller, and travel during festival or wedding season, booking a day or more ahead is safer.',
  },
  {
    q: 'Can I book a taxi for a full-day trip?',
    a: 'Yes. Full-day local use and day trips from Nagpur can be arranged with a vehicle and driver assigned to you for the day.',
  },
  {
    q: 'Do you provide taxis for weddings and events?',
    a: 'Yes. We arrange transportation for weddings, functions and events, including guest pickups and multi-vehicle requirements. Share your dates and expected group size for a suitable plan.',
  },
];

export const aboutParagraphs = [
  'Sagar Tours and Travels is a Nagpur-based taxi and travel service. We handle everyday city rides, airport and railway station transfers, and longer outstation journeys from Nagpur to destinations across Maharashtra and nearby states.',
  'Our focus is straightforward: a clean, comfortable vehicle, a professional driver who knows the route, and a booking process that takes a phone call, a WhatsApp message or a short form. Whether it is a single airport drop or transport for a family trip, the arrangement is the same — you tell us the trip, we confirm the vehicle and the fare.',
  'From compact sedans for solo travellers to MUVs and Tempo Travellers for groups, we match the vehicle to the journey and the number of people travelling, so you are not paying for more car than you need.',
];

export const footerServices = [
  'Airport Taxi',
  'Local Taxi',
  'Outstation Taxi',
  'One-Way Taxi',
  'Corporate Travel',
  'Wedding & Event Taxi',
  'Railway Station Transfer',
  'Tour & Travel',
];

export const footerRoutes = [
  'Nagpur to Tadoba',
  'Nagpur to Pench',
  'Nagpur to Amravati',
  'Nagpur to Jabalpur',
  'Nagpur to Pachmarhi',
  'Nagpur to Raipur',
];
