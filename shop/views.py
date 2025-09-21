from django.http import HttpResponse
from django.shortcuts import render


def home(request):
    """Strona główna sklepu"""
    return render(request, "shop/home.html")


def about(request):
    """Strona o nas"""
    return render(request, "shop/about.html")


def contact(request):
    """Strona kontaktowa"""
    return render(request, "shop/contact.html")
