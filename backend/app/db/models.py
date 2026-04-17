from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, DateTime, Numeric, Text, UUID, JSON
from sqlalchemy.orm import declarative_base, relationship
import datetime
import uuid

Base = declarative_base()

class Organization(Base):
    __tablename__ = 'organizations'
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    slug = Column(String(255), unique=True)
    domain = Column(String(255))
    digital_payments_enabled = Column(Boolean, default=True)
    
    users = relationship("User", back_populates="organization")
    properties = relationship("Property", back_populates="organization")

class User(Base):
    __tablename__ = 'users'
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey('organizations.id'))
    name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, index=True)
    password = Column(String(255))
    type = Column(String(50))  # superadmin, admin, manager, tenant, vendor
    status = Column(String(50), default='active')
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    # NOOR-specific extensions
    priorities = Column(String(255), nullable=True)
    
    organization = relationship("Organization", back_populates="users")
    leases = relationship("Lease", back_populates="tenant")

class Property(Base):
    __tablename__ = 'properties'
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey('organizations.id'))
    name = Column(String(255), index=True)
    address = Column(Text)
    city = Column(String(255))
    type = Column(String(255), default='residential') # commercial, apartment, residential
    description = Column(Text)
    
    latitude = Column(Float)
    longitude = Column(Float)
    
    image_url = Column(String(255), nullable=True)
    gallery = Column(JSON, nullable=True)
    amenities = Column(JSON, nullable=True)
    
    organization = relationship("Organization", back_populates="properties")
    units = relationship("Unit", back_populates="property")

class Unit(Base):
    __tablename__ = 'units'
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey('organizations.id'))
    property_id = Column(UUID(as_uuid=True), ForeignKey('properties.id'))
    unit_number = Column(String(255))
    bedrooms = Column(Integer)
    bathrooms = Column(Integer)
    size_sqft = Column(Integer)
    rent_amount = Column(Numeric(12, 2))
    status = Column(String(255), default='available') # available, occupied, maintenance
    
    image_url = Column(String(255), nullable=True)
    gallery = Column(JSON, nullable=True)
    
    property = relationship("Property", back_populates="units")
    leases = relationship("Lease", back_populates="unit")

class Lease(Base):
    __tablename__ = 'leases'
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey('organizations.id'))
    property_id = Column(UUID(as_uuid=True), ForeignKey('properties.id'))
    unit_id = Column(UUID(as_uuid=True), ForeignKey('units.id'))
    tenant_id = Column(UUID(as_uuid=True), ForeignKey('users.id'))
    
    start_date = Column(DateTime)
    end_date = Column(DateTime)
    rent_amount = Column(Numeric(12, 2))
    status = Column(String(50)) # active, expired, terminated
    
    tenant = relationship("User", back_populates="leases")
    unit = relationship("Unit", back_populates="leases")
    invoices = relationship("Invoice", back_populates="lease")

class Invoice(Base):
    __tablename__ = 'invoices'
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey('organizations.id'))
    lease_id = Column(UUID(as_uuid=True), ForeignKey('leases.id'))
    
    amount = Column(Numeric(12, 2))
    due_date = Column(DateTime)
    status = Column(String(50)) # paid, pending, void
    
    lease = relationship("Lease", back_populates="invoices")

class MaintenanceRequest(Base):
    __tablename__ = 'maintenance_requests'
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey('organizations.id'))
    property_id = Column(UUID(as_uuid=True), ForeignKey('properties.id'))
    unit_id = Column(UUID(as_uuid=True), ForeignKey('units.id'))
    tenant_id = Column(UUID(as_uuid=True), ForeignKey('users.id'))
    
    title = Column(String(255))
    description = Column(Text)
    category = Column(String(100))
    cost = Column(Numeric(12, 2), nullable=True)
    priority = Column(String(50)) # high, medium, low
class Booking(Base):
    __tablename__ = 'bookings'
    id = Column(UUID, primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID, ForeignKey('users.id'))
    property_id = Column(UUID, ForeignKey('properties.id'))
    time = Column(DateTime)
    status = Column(String(50), default='pending')

class Favorite(Base):
    __tablename__ = 'favorites'
    id = Column(UUID, primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID, ForeignKey('users.id'))
    property_id = Column(UUID, ForeignKey('properties.id'))
