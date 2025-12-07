import React, { useState } from "react";
import { Clock, DollarSign, Upload, MessageSquare, Briefcase } from "lucide-react";
import { getTheme } from "../Common/Theme";
import { orders } from "../Common/MockData";
import { OrderStatus } from "../Common/types";

export const OrdersDashboard = () => {
    const isDarkMode = true;
    const theme = getTheme(isDarkMode);
    const [activeOrderTab, setActiveOrderTab] = useState<OrderStatus>("Active");

    return (
        <div className="flex-1 flex flex-col h-full">
            <div className={`px-6 pb-5 pt-8 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} transition-all duration-500 z-30`}>
                <div className="flex justify-between items-center mb-2">
                    <div>
                    <h1 className="text-[28px] font-extrabold mb-0.5 tracking-tight leading-none transition-colors duration-500" style={{ color: theme.text }}>
                        My Orders
                    </h1>
                    <p className="text-[13px] font-medium transition-colors duration-500" style={{ color: theme.textSecondary }}>
                        Track your active jobs
                    </p>
                    </div>
                    <div className="bg-[#146068]/20 backdrop-blur-lg px-3 py-1.5 rounded-xl border border-[#146068]/40">
                    <Briefcase className="w-4 h-4 text-[#146068]" strokeWidth={2.5} />
                    </div>
                </div>
                {/* Status Tabs */}
                <div className={`p-1 rounded-[14px] ${theme.inputBg} border ${theme.inputBorder} flex mb-2`}>
                    {(["Active", "Revision", "Completed", "Cancelled"] as OrderStatus[]).map(status => (
                    <button
                        key={status}
                        onClick={() => setActiveOrderTab(status)}
                        className={`flex-1 py-2 rounded-[10px] text-[11px] font-bold transition-all duration-300 ${activeOrderTab === status ? 'bg-[#146068] text-white shadow-lg' : 'text-gray-400 hover:text-white'}`}
                    >
                        {status}
                    </button>
                    ))}
                </div>
            </div>

            <div
                className={`flex-1 overflow-y-auto px-6 py-5 bg-gradient-to-b ${theme.contentGradient} transition-all duration-500 pb-32`}
                style={{
                scrollbarWidth: "thin",
                scrollbarColor: theme.scrollbarColor,
                }}
            >
                <div className="space-y-4 animate-fade-in">
                    {orders.filter(o => o.status === activeOrderTab).length === 0 ? (
                    <div className="text-center py-10 opacity-50">
                        <div className="w-16 h-16 rounded-full bg-white/5 mx-auto flex items-center justify-center mb-4">
                            <Briefcase className="w-8 h-8 opacity-50" />
                        </div>
                        <h3 className="text-lg font-bold" style={{ color: theme.text }}>No {activeOrderTab} Orders</h3>
                        <p className="text-sm" style={{ color: theme.textSecondary }}>You don't have any jobs in this status.</p>
                    </div>
                    ) : (
                    orders.filter(o => o.status === activeOrderTab).map(order => (
                        <div key={order.id} className={`${theme.cardBg} backdrop-blur-lg rounded-[20px] p-5 border ${theme.cardBorder} relative overflow-hidden`}>
                            <div className="flex justify-between items-start mb-4">
                                <div className="flex items-center gap-3">
                                <div className="w-10 h-10 rounded-[12px] bg-[#f3bb19] flex items-center justify-center text-[13px] font-black text-black">
                                    {order.client.initials}
                                </div>
                                <div>
                                    <h3 className="text-[15px] font-bold leading-tight mb-0.5" style={{ color: theme.text }}>{order.title}</h3>
                                    <p className="text-[12px]" style={{ color: theme.textSecondary }}>Client: {order.client.name}</p>
                                </div>
                                </div>
                                <div className={`px-2.5 py-1 rounded-lg text-[10px] font-bold border ${order.status === 'Active' ? 'bg-[#146068]/20 text-[#93ccce] border-[#146068]/40' : order.status === 'Revision' ? 'bg-[#f3bb19]/20 text-[#f3bb19] border-[#f3bb19]/40' : 'bg-white/5 text-gray-400 border-white/10'}`}>
                                {order.status.toUpperCase()}
                                </div>
                            </div>

                            {/* Dashboard Metrics for Active Jobs */}
                            {order.status === 'Active' && (
                                <div className="flex gap-3 mb-4">
                                <div className="flex-1 p-3 rounded-[14px] bg-[#146068]/10 border border-[#146068]/20 flex flex-col items-center">
                                    <Clock className="w-4 h-4 text-[#146068] mb-1" />
                                    <span className="text-[14px] font-black text-[#146068]">{order.timeLeft}</span>
                                    <span className="text-[9px] font-bold opacity-60 uppercase">Time Left</span>
                                </div>
                                <div className="flex-1 p-3 rounded-[14px] bg-white/5 border border-white/10 flex flex-col items-center">
                                    <DollarSign className="w-4 h-4 text-[#f4f3f1] mb-1" />
                                    <span className="text-[14px] font-black text-[#f4f3f1]">{order.price}</span>
                                    <span className="text-[9px] font-bold opacity-60 uppercase">Budget</span>
                                </div>
                                </div>
                            )}

                            {/* Actions */}
                            <div className="pt-3 border-t border-white/10 flex gap-3">
                                {(order.status === 'Active' || order.status === 'Revision') ? (
                                <button className="flex-1 h-[40px] bg-[#146068] rounded-[12px] text-[12px] font-bold text-white shadow-lg hover:scale-[1.02] active:scale-95 transition-all flex items-center justify-center gap-2">
                                    <Upload className="w-4 h-4" /> Deliver Work
                                </button>
                                ) : (
                                <button className="flex-1 h-[40px] bg-white/5 border border-white/10 rounded-[12px] text-[12px] font-bold text-white hover:bg-white/10 active:scale-95 transition-all">
                                    View Details
                                </button>
                                )}
                                <button className="w-[40px] h-[40px] rounded-[12px] border border-white/10 flex items-center justify-center hover:bg-white/5 active:scale-95 transition-all">
                                <MessageSquare className="w-4 h-4 text-white/70" />
                                </button>
                            </div>
                        </div>
                    ))
                    )}
                </div>
            </div>
        </div>
    );
};