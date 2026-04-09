from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, DateTime
from sqlalchemy.orm import declarative_base, relationship
import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    full_name = Column(String, nullable=True)
    priorities = Column(String, default="Standard")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    favorites = relationship("Favorite", back_populates="user")

class Favorite(Base):
    __tablename__ = 'favorites'
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    property_id = Column(Integer, ForeignKey('properties.id'))
    
    user = relationship("User", back_populates="favorites")
    property = relationship("Property")

class Property(Base):
    __tablename__ = 'properties'
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    address = Column(String)
    zone_number = Column(Integer, nullable=True)
    street_number = Column(Integer, nullable=True)
    building_number = Column(Integer, nullable=True)
    
    # Replaced PostGIS geometry with flat coordinates for SQLite compatibility
    latitude = Column(Float)
    longitude = Column(Float)
    
    zoning_type = Column(String)
    is_active = Column(Boolean, default=True)
    image_url = Column(String, nullable=True)
    furnished_image_url = Column(String, nullable=True)
    tour_url = Column(String, nullable=True)
    
    units = relationship("Unit", back_populates="property")

class Unit(Base):
    __tablename__ = 'units'
    
    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey('properties.id'))
    unit_number = Column(String)
    bedrooms = Column(Integer)
    bathrooms = Column(Float)
    rent_price = Column(Float)
    lease_end = Column(DateTime, nullable=True)
    pets_allowed = Column(Boolean, default=False)
    
    property = relationship("Property", back_populates="units")

class Booking(Base):
    __tablename__ = 'bookings'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    property_id = Column(Integer, ForeignKey('properties.id'))
    booking_time = Column(String) 
    status = Column(String, default="Pending")
    notes = Column(String, nullable=True)

class NeighborhoodPOI(Base):
    __tablename__ = 'neighborhood_pois'
    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey('properties.id')) 
    district_name = Column(String) 
    name = Column(String)
    poi_type = Column(String) 
    distance_meters = Column(Integer, default=500)
    distance_description = Column(String)
    perks = Column(String, nullable=True) # JSON representation

    property = relationship("Property")
