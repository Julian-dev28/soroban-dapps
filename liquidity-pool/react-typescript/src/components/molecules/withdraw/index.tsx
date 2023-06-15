import React, { FunctionComponent, useState } from 'react'

import { SorobanContextType } from "@soroban-react/core";
import { useSendTransaction, contractTransaction } from '@soroban-react/contracts'
import * as SorobanClient from 'soroban-client'

import { LoadingButton } from '@mui/lab';

import styles from './styles.module.scss'
import { Constants } from 'shared/constants'
import { IToken } from "interfaces/soroban/token"
import { IReserves } from "interfaces/soroban/liquidityPool"
import { Icon, IconNames, InputPercentage, InputSlider, Tooltip } from "components/atoms"
import { useLoadTotalShares } from "services/liquidityPool"
import { useLoadTokenBalance } from "services/token"
import { Utils } from 'shared/utils';
import { ErrorText } from 'components/atoms/error-text';
import { bigNumberToI128 } from 'shared/convert';


interface IFormValues {
    sharePercent: string;
    maxSlippage: string;
}

interface IWithdraw {
    sorobanContext: SorobanContextType;
    account: string;
    tokenA: IToken;
    tokenB: IToken;
    reserves: IReserves;
}

const Withdraw: FunctionComponent<IWithdraw> = ({ sorobanContext, account, tokenA, tokenB, reserves }) => {
    const [isSubmitting, setSubmitting] = useState(false)
    const [error, setError] = useState(false)
    const [formValues, setFormValues] = useState<IFormValues>({
        sharePercent: "0",
        maxSlippage: "0.5",
    });

    const { sendTransaction } = useSendTransaction()

    const slippageFactor = parseFloat(formValues.maxSlippage) / 100
    const totalShares = useLoadTotalShares(sorobanContext, Constants.LIQUIDITY_POOL_ID);
    const accBalanceShares = useLoadTokenBalance(sorobanContext, Constants.SHARE_ID, account);

    const shareAmount = accBalanceShares.multipliedBy(parseInt(formValues.sharePercent) / 100);
    const tokenATotalWithSlippage = shareAmount
        .dividedBy(totalShares)
        .multipliedBy(reserves.reservesA)
        .times(1 - slippageFactor);
    const tokenBTotalWithSlippage = shareAmount
        .dividedBy(totalShares)
        .multipliedBy(reserves.reservesB)
        .times(1 - slippageFactor);


    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>): void => {
        const { name, value } = e.target;
        setFormValues({ ...formValues, [name]: value || 0 });
    };

    const handleSubmit = async (e: React.FormEvent): Promise<void> => {
        e.preventDefault();
        setSubmitting(true)
        setError(false)

        try {
            if (!sorobanContext.server) {
                throw new Error("Not connected to server");
            }
            const source = await sorobanContext.server.getAccount(account);

            const networkPassphrase = sorobanContext.activeChain?.networkPassphrase
            if (!networkPassphrase) {
                throw new Error("Invalid network passphrase");
            }

            // Method: withdraw(e: Env, to: Address, share_amount: i128, min_a: i128, min_b: i128) -> (i128, i128);
            const tx = contractTransaction({
                source,
                networkPassphrase: networkPassphrase,
                contractId: Constants.LIQUIDITY_POOL_ID,
                method: 'withdraw',
                params: [
                    new SorobanClient.Address(account).toScVal(),
                    bigNumberToI128(shareAmount),
                    bigNumberToI128(tokenATotalWithSlippage),
                    bigNumberToI128(tokenBTotalWithSlippage),
                ]
            });

            const result = await sendTransaction(tx, { sorobanContext });
            sorobanContext.connect()
            // Process the result or perform any additional actions

        } catch (error) {
            console.error(error);
            setError(true)
        }
        setSubmitting(false)
        setFormValues({
            ...formValues,
            sharePercent: "0"
        })
    };

    return (
        <form>
            <div className={styles.formContent}>
                <div className={styles.slider}>
                    <InputSlider
                        label="Pool Share amount"
                        name="sharePercent"
                        value={formValues.sharePercent}
                        onChange={handleInputChange}
                    />
                </div>
                <div className={styles.info}>
                    <div className={styles.contentLeft}>
                        <div className={styles.infoItem}>
                            <div className={styles.label}>
                                {tokenA.symbol} amount
                                <Tooltip title={"Estimated price based on the last pool query. If at the time of submission the amount is lower than this, the transaction will be cancelled."} placement="top">
                                    <div> <Icon name={IconNames.info} /></div>
                                </Tooltip>
                            </div>
                            <div>
                                {Utils.formatAmount(tokenATotalWithSlippage, tokenA.decimals)} {tokenA.symbol}
                            </div>
                        </div>
                        <div className={styles.infoItem}>
                            <div className={styles.label}>
                                {tokenB.symbol} amount
                                <Tooltip title={"Estimated price based on the last pool query. If at the time of submission the amount is lower than this, the transaction will be cancelled."} placement="top">
                                    <div> <Icon name={IconNames.info} /></div>
                                </Tooltip>
                            </div>
                            <div>
                                {Utils.formatAmount(tokenBTotalWithSlippage, tokenB.decimals)} {tokenB.symbol}
                            </div>
                        </div>
                    </div>
                    <div className={styles.contentRight}>
                        <InputPercentage
                            label="Max slippage"
                            name="maxSlippage"
                            value={formValues.maxSlippage}
                            onChange={handleInputChange}
                            helpText="The percentage of variation accepted for the amount of each currency received."
                        />
                    </div>
                </div>
            </div>
            <div>
                <LoadingButton
                    variant="contained"
                    onClick={handleSubmit}
                    color="primary"
                    disableElevation
                    fullWidth
                    loading={isSubmitting}
                >
                    Withdraw
                </LoadingButton>
                {error &&
                    <div className={styles.error}>
                        <ErrorText text="Transaction failed. Try to increase the slippage for more chances of success." />
                    </div>
                }
            </div>
        </form>
    )
}


export { Withdraw }