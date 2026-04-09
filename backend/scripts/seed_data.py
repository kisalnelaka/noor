import os
import sys

# 🧬 Self-Healing Path: Ensure the script can see 'app' regardless of launch context
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.db.models import Base, Property, Unit, NeighborhoodPOI, Booking, User
from app.api.auth import get_password_hash
from reportlab.pdfgen import canvas
from datetime import datetime, timedelta
import random

from app.db.database import engine, SessionLocal, DATABASE_URL

def seed_db():
    print("[Seed] Dropping and Recreating SQLite Database Tables...")
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    print("[Seed] Creating NOOR User Profiles...")
    demo_user = User(email="demo@noor.qa", hashed_password=get_password_hash("noor2026"), full_name="Kisal Executive", priorities="Investment & High ROI")
    sarah = User(email="sarah@qatar.com", hashed_password=get_password_hash("noor2026"), full_name="Sarah Thompson", priorities="Family, Schools, Villas")
    khalid = User(email="khalid@holding.qa", hashed_password=get_password_hash("noor2026"), full_name="Khalid Al Thani", priorities="Commercial, Bulk Yields")
    
    db.add_all([demo_user, sarah, khalid])
    db.commit()
    
    # 🏙️ NOOR V4: DATA FLOOD - Generate 50+ Premium Properties
    # 🏙️ NOOR V5: ANCHOR PROPERTIES (Guaranteed Diversity with Media)
    anchor_props = [
        Property(name="The Horizon Tower (برج الأفق)", address="West Bay, Doha", zone_number=61, street_number=830, building_number=14, zoning_type="Residential High-Density", latitude=25.3182, longitude=51.5285, 
                 image_url="https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
                 furnished_image_url="https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
                 tour_url="https://images.unsplash.com/photo-1557804506-669a67965ba0?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80"),
        Property(name="Al Sadd Budget Studio (استوديو السد الاقتصادي)", address="Al Sadd, Doha", zone_number=38, street_number=230, building_number=5, zoning_type="Mid-Rise Apartment", latitude=25.281, longitude=51.503,
                 image_url="https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80"),
        Property(name="The Pearl Royal Palms Villa (فيلا رويال بالمز في اللؤلؤة)", address="The Pearl, Doha", zone_number=66, street_number=120, building_number=1, zoning_type="Beachfront Villa", latitude=25.367, longitude=51.558,
                 image_url="https://images.unsplash.com/photo-1613977257363-707ba9348227?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
                 furnished_image_url="https://images.unsplash.com/photo-1613545325278-f24b0cae1224?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
                 tour_url="https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80"),
        Property(name="Lusail Smart Hub (لوسيل سمارت هب)", address="Lusail, Doha", zone_number=69, street_number=450, building_number=8, zoning_type="Modern Condo", latitude=25.421, longitude=51.512,
                 image_url="https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80")
    ]
    db.add_all(anchor_props)
    db.commit()
    
    tower_names = ["Azure", "Oasis", "Marina", "Platinum", "Onyx", "Crystal", "Radiant", "Titanium", "Emerald", "Sapphire", "Velvet"]
    districts = [
        {"name": "West Bay", "zone": 61, "lat": 25.318, "lon": 51.528, "types": ["High-Rise", "Penthouse"]},
        {"name": "The Pearl", "zone": 66, "lat": 25.367, "lon": 51.558, "types": ["Luxury Apartment", "Beachfront Villa"]},
        {"name": "Lusail", "zone": 69, "lat": 25.421, "lon": 51.512, "types": ["Modern Condo", "Smart Studio"]},
        {"name": "Mushaireb", "zone": 3, "lat": 25.286, "lon": 51.523, "types": ["Sustainable Loft", "Heritage Home"]}
    ]
    
    props = []
    for i in range(50): # Expanded to 54 total properties
        dist = random.choice(districts)
        tower_names = [
            ("Azure", "أزور"), ("Oasis", "أوسيس"), ("Marina", "مارينا"), 
            ("Platinum", "بلاتينيوم"), ("Onyx", "أونيكس"), ("Crystal", "كريستال"), 
            ("Radiant", "راديانت"), ("Titanium", "تيتانيوم"), ("Emerald", "إيميرالد"), 
            ("Sapphire", "سافاير"), ("Velvet", "فيلفيت")
        ]
        tower_eng, tower_arb = random.choice(tower_names)
        suffix_eng, suffix_arb = random.choice([("Tower", "برج"), ("Residences", "ريزيدنس"), ("Plaza", "بلازا"), ("Gardens", "حدائق")])
        name = f"{tower_eng} {suffix_eng} {i+10} ({tower_arb} {suffix_arb} {i+10})"
        
        # 🏙️ Diversified Media Pool for NOOR V5
        media_pool = [
            "https://images.unsplash.com/photo-1574362848149-11496d93a7c7?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1560185127-6ed189bf02f4?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1600585154542-63793e4334f5?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
            "https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80",
        ]
        img_url = random.choice(media_pool)

        props.append(Property(
            name=name,
            address=f"{dist['name']}, Doha",
            zone_number=dist['zone'],
            street_number=random.randint(100, 999),
            building_number=random.randint(1, 150),
            zoning_type=random.choice(dist['types']),
            latitude=dist['lat'] + (random.random() - 0.5) * 0.01,
            longitude=dist['lon'] + (random.random() - 0.5) * 0.01,
            image_url=img_url
        ))
    
    db.add_all(props)
    db.commit()
    
    # 🏙️ Combined list of all properties for Unit seeding
    all_props = anchor_props + props
    
    # Generate Units (approx 100 total)
    units = []
    for p in all_props:
        num_units = random.randint(2, 5)
        # Determine price category based on property name/location
        is_luxury = "Pearl" in p.name or "Horizon" in p.name or "Villa" in p.name
        is_budget = "Al Sadd" in p.name
        
        for i in range(1, num_units + 1):
            if is_budget:
                rent = random.randint(4000, 5500)
            elif is_luxury:
                rent = random.randint(18000, 30000)
            else:
                rent = random.randint(7000, 15000)
                
            units.append(
                Unit(
                    property_id=p.id,
                    unit_number=f"{random.randint(1,40)}{random.randint(0,9)}",
                    bedrooms=random.randint(1, 4),
                    bathrooms=1.0 * random.randint(1, 3),
                    rent_price=rent, # 🏙️ Logic-driven pricing for diversity
                    lease_end=datetime.now() + timedelta(days=random.randint(-30, 365)),
                    pets_allowed=random.choice([True, False])
                )
            )
            
    db.add_all(units)
    db.commit()
    
    # 🏙️ NOOR: NEIGHBORHOOD POI SEEDING (Enriched for proximity math)
    import json
    pois = [
        NeighborhoodPOI(property_id=1, district_name="West Bay", name="City Centre Mall", poi_type="Mall", distance_meters=350, distance_description="5 mins walk", perks=json.dumps({"Metro": "West Bay Station", "Stores": ["Carrefour", "Apple"], "Vibe": "The heart of Doha shopping"})),
        NeighborhoodPOI(property_id=1, district_name="West Bay", name="West Bay Metro", poi_type="Metro", distance_meters=400, distance_description="6 mins walk", perks=json.dumps({"Line": "Red Line", "Access": "Direct Skyline view", "Vibe": "Professional hub"})),
        NeighborhoodPOI(property_id=3, district_name="The Pearl", name="Porto Arabia Marina", poi_type="Marina", distance_meters=200, distance_description="Direct access", perks=json.dumps({"Metro": "Legtaifiya (Transfer)", "Schools": ["United School Intl"], "Vibe": "The Riviera of the Middle East"})),
        NeighborhoodPOI(property_id=3, district_name="The Pearl", name="United School Intl.", poi_type="School", distance_meters=1200, distance_description="4 mins drive", perks=json.dumps({"Metro": "None", "Schools": ["United School Intl"], "Vibe": "Family-forward expat living"})),
        NeighborhoodPOI(property_id=6, district_name="Lusail", name="Place Vendôme Mall", poi_type="Mall", distance_meters=800, distance_description="6 mins drive", perks=json.dumps({"Metro": "Lusail Tram", "Schools": ["Edison International"], "Vibe": "Ultra-modern luxury lifestyle"})),
        NeighborhoodPOI(property_id=6, district_name="Lusail", name="Lusail Metro Station", poi_type="Metro", distance_meters=1500, distance_description="10 mins walk", perks=json.dumps({"Metro": "Red Line Terminus", "Schools": ["ACS International"], "Vibe": "Smart city convenience"})),
        NeighborhoodPOI(property_id=10, district_name="Al Sadd", name="Al Sadd Metro", poi_type="Metro", distance_meters=300, distance_description="4 mins walk", perks=json.dumps({"Metro": "Gold Line", "Vibe": "Bustling city center"})),
        NeighborhoodPOI(property_id=10, district_name="Al Sadd", name="Royal Plaza", poi_type="Mall", distance_meters=500, distance_description="7 mins walk", perks=json.dumps({"Vibe": "Classic shopping experience"}))
    ]
    db.add_all(pois)
    db.commit()
    
    # 📅 V5: MOCK BOOKINGS (For the User Portfolio)
    print("[Seed] Generating Mock Bookings for Demo User...")
    bookings = [
        Booking(user_id=demo_user.id, property_id=anchor_props[0].id, booking_time=(datetime.now() + timedelta(days=2)).strftime("%A at %I:%M %p"), status="Confirmed", notes="Interested in high-floor units."),
        Booking(user_id=demo_user.id, property_id=anchor_props[2].id, booking_time=(datetime.now() + timedelta(days=5)).strftime("%A at %I:%M %p"), status="Pending", notes="Bring school brochures.")
    ]
    db.add_all(bookings)
    db.commit()
    
    print(f"[Seed] Successfully flooded database with 1 User, {len(props)} properties, {len(units)} units, and {len(pois)} POIs.")
    print("[Seed] Generated Properties and Units in noor.db SQLite file.")

def generate_mock_pdfs():
    print("[Seed] Generating Mock Leases and Permits...")
    os.makedirs("sample_docs", exist_ok=True)
    
    # 1. Lease Agreement (English)
    c = canvas.Canvas("sample_docs/lease_100_skyline.pdf")
    c.drawString(100, 800, "LEASE AGREEMENT - The Horizon Tower")
    c.drawString(100, 780, "Property: Zone 61, Street 830, Building 14 - Doha")
    c.drawString(100, 740, "Terms & Conditions:")
    c.drawString(100, 720, "1. Early termination carries a 5% rent penalty.")
    c.drawString(100, 700, "2. Pets are allowed but require a $500 non-refundable deposit.")
    c.drawString(100, 680, "3. Quiet hours are from 10 PM to 7 AM.")
    c.save()
    
    # 2. Zoning Permit
    c2 = canvas.Canvas("sample_docs/zoning_warehouse.pdf")
    c2.drawString(100, 800, "ZONING EXCEPTION PERMIT #Z-90210")
    c2.drawString(100, 780, "Address: 5 Warehouse St")
    c2.drawString(100, 740, "Classification: Mixed-Use Light Industrial")
    c2.drawString(100, 720, "Notes: Approved for residential loft conversion.")
    c2.save()

    # 3. Arabic Lease/Document snippet (Mock using string encoding for RAG parsing)
    with open("sample_docs/arabic_lease_snippet.txt", "w", encoding="utf-8") as f:
        f.write("اتفاقية الإيجار\n")
        f.write("المنطقة 61، شارع 830، مبنى 14\n")
        f.write("يُسمح بالحيوانات الأليفة ولكن يتطلب وديعة غير مستردة.\n")

    print("[Seed] Mock docs saved to sample_docs/")
    
if __name__ == "__main__":
    seed_db()
    generate_mock_pdfs()
