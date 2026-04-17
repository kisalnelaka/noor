from sqlalchemy.orm import Session
from app.db.database import SessionLocal, engine
from app.db.models import Base, Property, Unit, User, Booking, Favorite
import uuid
import random
import os

def seed_db():
    """Main seeder function called by lifespan."""
    import time
    print("[Seeder] Warming engine and waiting for volume stability...", flush=True)
    time.sleep(1.5) 
    
    print("[Seeder] Purging legacy records...")
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # 1. Create Demo User
        print("[Seeder] Creating demo user: Kisal Nelaka...")
        demo_user = User(
            name="Kisal Nelaka",
            email="demo@noor.qa",
            password="noor2026", 
            priorities="Lifestyle & Premium Service"
        )
        db.add(demo_user)

        # 2. Districts & Neighborhoods
        districts = {
            "West Bay": {"lat": 25.317, "lng": 51.524, "desc": "Business & Skyscrapers"},
            "Lusail": {"lat": 25.421, "lng": 51.512, "desc": "Smart City & Future"},
            "The Pearl": {"lat": 25.369, "lng": 51.551, "desc": "Mediterranean Luxury"},
            "Al Sadd": {"lat": 25.286, "lng": 51.503, "desc": "Commercial Heart & Culture"},
            "Msheireb": {"lat": 25.289, "lng": 51.527, "desc": "Modern Qatari Heritage"}
        }

        # 3. Comprehensive Property Inventory (50 Properties)
        property_types = ["Tower", "Residence", "Manor", "Heights", "Villas", "Oasis", "Vista"]
        adjectives = ["Sapphire", "Velvet", "Onyx", "Azure", "Golden", "Emerald", "Regal", "Zenith", "Horizon", "Grand"]
        
        all_props = []
        for i in range(1, 51):
            district_name = list(districts.keys())[i % len(districts)]
            dist_data = districts[district_name]
            
            p_name = f"{random.choice(adjectives)} {random.choice(property_types)} {i}"
            
            prop = Property(
                name=p_name,
                address=f"{district_name} Phase {random.randint(1,5)}, Doha",
                latitude=dist_data["lat"] + (random.uniform(-0.002, 0.002)),
                longitude=dist_data["lng"] + (random.uniform(-0.002, 0.002)),
                image_url=f"https://images.unsplash.com/photo-{1580587767303 + (i % 10)}?auto=format&fit=crop&q=80&w=1200"
            )
            db.add(prop)
            all_props.append(prop)
            
            # Add units
            for j in range(1, random.randint(3, 5)):
                price = float(random.randint(8000, 45000))
                unit = Unit(
                    property_id=prop.id,
                    unit_number=f"{random.randint(10, 40)}{random.choice(['A', 'B', 'C'])}",
                    rent_amount=price,
                    bedrooms=random.randint(1, 4),
                    bathrooms=float(random.randint(1, 3))
                )
                db.add(unit)

        db.commit()
        print(f"[Seeder] SUCCESS: Deployed {len(all_props)} premium properties to NOOR core.")

    except Exception as e:
        print(f"[Seeder] FATAL ERROR: {e}")
        db.rollback()
    finally:
        db.close()

def generate_mock_pdfs():
    """Satisfy interface."""
    pass

if __name__ == "__main__":
    seed_db()
    generate_mock_pdfs()
