defmodule PantryWeb.ConfirmationLive do
  use PantryWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    you must confirm your email address before you can continue
    """
  end
end
