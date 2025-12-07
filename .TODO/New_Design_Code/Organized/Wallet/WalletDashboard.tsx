import React from "react";
import { Wallet, CreditCard, ArrowUpRight, Plus, ArrowDownLeft } from "lucide-react";
import { getTheme } from "../Common/Theme";
import { walletData } from "../Common/MockData";

export const WalletDashboard = () => {
    const isDarkMode = true;
    const theme = getTheme(isDarkMode);

    return (
        <div className="flex-1 flex flex-col h-full">
            <div className={`px-6 pb-5 pt-8 ${theme.headerBg} backdrop-blur-xl border-b ${theme.headerBorder} transition-all duration-500 z-30`}>
                <div className="flex justify-between items-center mb-4">
                    <div>
                    <h1 className="text-[28px] font-extrabold mb-0.5 tracking-tight leading-none transition-colors duration-500" style={{ color: theme.text }}>
                        My Wallet
                    </h1>
                    <p className="text-[13px] font-medium transition-colors duration-500" style={{ color: theme.textSecondary }}>
                        Manage your earnings
                    </p>
                    </div>
                    <div className="bg-[#146068]/20 backdrop-blur-lg px-3 py-1.5 rounded-xl border border-[#146068]/40">
                    <CreditCard className="w-4 h-4 text-[#146068]" strokeWidth={2.5} />
                    </div>
                </div>
            </div>

            <div
                className={`flex-1 overflow-y-auto px-6 py-5 bg-gradient-to-b ${theme.contentGradient} transition-all duration-500 pb-32`}
                style={{
                scrollbarWidth: "thin",
                scrollbarColor: theme.scrollbarColor,
                }}
            >
                <div className="space-y-6 animate-fade-in">
                    {/* Glass Credit Card */}
                    <div className="w-full h-[200px] rounded-[24px] bg-gradient-to-br from-[#146068] to-[#0c3b40] relative overflow-hidden p-6 flex flex-col justify-between shadow-2xl border border-white/10">
                        <div className="absolute inset-0 bg-noise opacity-10 mix-blend-overlay" />
                        <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full blur-3xl -mr-10 -mt-10" />
                        <div className="absolute bottom-0 left-0 w-32 h-32 bg-[#f3bb19]/20 rounded-full blur-3xl -ml-10 -mb-10" />
                        
                        <div className="relative z-10 flex justify-between items-start">
                            <div>
                                <span className="text-[12px] font-medium text-white/70 block mb-1">Total Balance</span>
                                <h2 className="text-[32px] font-black text-white tracking-tight">${walletData.totalBalance}</h2>
                            </div>
                            <Wallet className="w-6 h-6 text-white/50" />
                        </div>
                        
                        <div className="relative z-10">
                            <div className="flex gap-8 mb-6">
                                <div>
                                <span className="text-[10px] font-bold text-white/60 block uppercase tracking-wide">Available</span>
                                <span className="text-[14px] font-bold text-white">${walletData.availableBalance}</span>
                                </div>
                                <div>
                                <span className="text-[10px] font-bold text-white/60 block uppercase tracking-wide">In Escrow</span>
                                <span className="text-[14px] font-bold text-[#f3bb19]">${walletData.escrowBalance}</span>
                                </div>
                            </div>
                            <div className="flex justify-between items-end">
                                <div className="text-[12px] font-mono text-white/50">**** **** **** {walletData.cardLast4}</div>
                                <div className="w-8 h-5 bg-white/20 rounded flex items-center justify-center">
                                <div className="w-4 h-4 rounded-full bg-red-500/80 -mr-2 mix-blend-screen" />
                                <div className="w-4 h-4 rounded-full bg-yellow-500/80 mix-blend-screen" />
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Action Buttons */}
                    <div className="flex gap-3">
                        <button className="flex-1 h-[50px] bg-[#f3bb19] rounded-[16px] text-black font-black text-[14px] shadow-lg shadow-[#f3bb19]/20 hover:scale-[1.02] active:scale-95 transition-transform flex items-center justify-center gap-2">
                            <ArrowUpRight className="w-4 h-4" /> Withdraw
                        </button>
                        <button className={`flex-1 h-[50px] ${theme.cardBg} border ${theme.cardBorder} rounded-[16px] font-bold text-[14px] hover:bg-white/5 active:scale-95 transition-transform flex items-center justify-center gap-2`} style={{ color: theme.text }}>
                            <Plus className="w-4 h-4" /> Top Up
                        </button>
                    </div>

                    {/* Transaction History */}
                    <div>
                        <div className="flex justify-between items-center mb-4">
                            <h3 className="text-[16px] font-bold" style={{ color: theme.text }}>Recent Transactions</h3>
                            <button className="text-[12px] font-bold text-[#146068]">View All</button>
                        </div>
                        <div className="space-y-3">
                            {walletData.transactions.map(tx => (
                                <div key={tx.id} className={`${theme.cardBg} backdrop-blur-lg rounded-[16px] p-4 border ${theme.cardBorder} flex items-center justify-between`}>
                                <div className="flex items-center gap-3">
                                    <div className={`w-10 h-10 rounded-full flex items-center justify-center border ${theme.cardBorder} ${tx.isPositive ? 'bg-[#146068]/20 text-[#146068]' : 'bg-[#f49d9d]/20 text-[#f49d9d]'}`}>
                                        {tx.isPositive ? <ArrowDownLeft className="w-5 h-5" /> : <ArrowUpRight className="w-5 h-5" />}
                                    </div>
                                    <div>
                                        <div className="text-[13px] font-bold mb-0.5" style={{ color: theme.text }}>{tx.description}</div>
                                        <div className="text-[11px]" style={{ color: theme.textSecondary }}>{tx.date}</div>
                                    </div>
                                </div>
                                <div className="text-right">
                                    <div className={`text-[14px] font-black ${tx.isPositive ? 'text-[#146068]' : 'text-[#f49d9d]'}`}>
                                        {tx.isPositive ? '+' : '-'}${tx.amount}
                                    </div>
                                    <div className={`text-[10px] font-bold uppercase ${tx.status === 'completed' ? 'text-[#93ccce]' : 'text-[#f3bb19]'}`}>
                                        {tx.status}
                                    </div>
                                </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};