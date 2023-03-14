import React from  'react';
import {BrowserRouter as Router, Routes, Route} from 'react-router-dom';
import AdminDashboard from './admin/AdminDashboard';
import AdminOrders from './admin/AdminOrders';
import CustomerList from './admin/CustomerList';
import Product from './admin/Product';
import Login from './Login';
import ProductDisplay from './users/ProductDisplay';
import Registration from './Registration';
import Cart from './users/Cart';
import Dashboard from './users/Dashboard';
import Orders from './users/Orders';
import Profile from './users/Profile';

export default function RouterPage(){
    
    return(
        <Router>
            <Routes>
                <Route exact path='/' element={ <Login /> } />
                <Route path='/registration' element={ <Registration /> } />
                <Route path='/dashboard' element={ <Dashboard /> } />                
                <Route path='/myorders' element={ <Orders /> } />
                <Route path='/profile' element={ <Profile /> } />
                <Route path='/cart' element={ <Cart /> } />

                <Route path='/admindashboard' element={ <AdminDashboard /> } />
                <Route path='/adminorders' element={ <AdminOrders /> } />
                <Route path='/customers' element={ <CustomerList /> } />
                <Route path='/product' element={ <Product /> } />

                <Route path='/products' element={ <ProductDisplay /> } />
            </Routes>
        </Router>
    )
}